
include { SAMTOOLS_FASTQ                                          } from './modules/samtools/fastq'
include { SEQUENCING_QC                                           } from './workflows/sequencing_qc'
include { ASSEMBLE_READS                                         } from './workflows/assemble_reads'
include { validateParameters; paramsSummaryLog; samplesheetToList } from 'plugin/nf-schema'


nextflow.preview.output = true

def get_samplesheet() {
	ss = [
		lr_ch: Channel.empty(),
		sr_ch: Channel.empty()
	]
	if (params.samplesheet) {
		SS = Channel.fromList(samplesheetToList(params.samplesheet, "assets/schema_samplesheet.json"))
			.multiMap({x ->
				lr_ch: [[sample_id:x[0].sample_id],x[0].long_reads]
				sr_ch: [[sample_id:x[0].sample_id],[x[0].short_reads_1,x[0].short_reads_2]]
			})
		ss.lr_ch = SS.lr_ch
		ss.sr_ch = SS.sr_ch
	} else {
		if (params.long_reads) {
			ss.lr_ch = Channel.fromPath(params.long_reads)
					.map({x -> tuple(["sample_id":x.name.replaceAll(/\.(fastq\.gz|fq\.gz|bam|cram)$/,'')],x)})
		}
		if (params.short_reads) {
			ss.sr_ch = Channel
					.fromFilePairs(params.short_reads,size:-1) { file -> file.name.replaceAll(/_(R?[12])(_001)?\.(fq|fastq)\.gz$/, '') }
					.map({id,x -> [["sample_id":id],x]})
		}	
	}
	// Filter missing values
	ss.sr_ch = ss.sr_ch.map({x,y -> [x,y.findAll({v->v})]}).filter({x,y -> y})
	ss.lr_ch = ss.lr_ch.filter({x,y -> y})
	return ss	
}


workflow {
	main:
		// Validate parameters and print summary of supplied ones
		validateParameters()
		log.info(paramsSummaryLog(workflow))

		// Prepare SampleSheet
		ss = get_samplesheet()
		
		// CONVERT long_reads given in BAM/CRAM format into FASTQ format
		ss.lr_ch = ss.lr_ch.branch({meta,f -> 
			bam: f.name =~ /\.(bam|cram)$/
			fq: true
		})
		ss.lr_ch = ss.lr_ch.fq.mix(SAMTOOLS_FASTQ(ss.lr_ch.bam))
				
		// Reads Quality Controls
		SEQUENCING_QC(
			ss.lr_ch.filter({!params.skip_reads_qc}),
			ss.sr_ch.filter({!params.skip_reads_qc})
		)

		// Reads assembly3
		ASSEMBLE_READS(ss.lr_ch,ss.sr_ch)
		//ASSEMBLY_QC(ss.asm_ch,ss.lr_ch,ss.sr_ch)

	publish:
		sequencing_qc = SEQUENCING_QC.out.qc
}



output {
	sequencing_qc {
		path { x -> x[1] >> "." }
		mode 'copy'
	}
}
