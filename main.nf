
include { SAMTOOLS_FASTQ                   } from './modules/samtools/fastq'
include { UNICYCLER    as LONG_UNICYCLER   } from './modules/unicycler'
include { UNICYCLER    as SHORT_UNICYCLER  } from './modules/unicycler'
include { UNICYCLER    as HYBRID_UNICYCLER } from './modules/unicycler'
include { HYBRACTER    as LONG_HYBRACTER   } from './modules/hybracter'
include { HYBRACTER    as HYBRID_HYBRACTER } from './modules/hybracter'
include { SPADES       as SHORT_SPADES     } from './modules/spades'
include { FLYE_MEDAKA  as LONG_FLYE_MEDAKA } from './subworkflows/flye_medaka'
include { PILON_POLISH as PILON_POLISH_ROUND1 } from './subworkflows/pilon_polish'
include { PILON_POLISH as PILON_POLISH_ROUND2 } from './subworkflows/pilon_polish'
include { PILON_POLISH as PILON_POLISH_ROUND3 } from './subworkflows/pilon_polish'
include { validateParameters; paramsSummaryLog; samplesheetToList } from 'plugin/nf-schema'


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

process HYBRID_FLYE_MEDAKA_PILON_FOLDER {
    input:
    	tuple val(meta),path('flye_medaka'),path('flye_medaka_pilon/03_pilon_round1'),path('flye_medaka_pilon/04_pilon_round2'),path('flye_medaka_pilon/05_pilon_round3')
    output:
    	tuple val(meta),path("flye_medaka_pilon",type: 'dir')
    script:
    """
    	cp --no-dereference flye_medaka/* flye_medaka_pilon/
    """
}

workflow HYBRID_FLYE_MEDAKA_PILON {
	take:
		flye_medaka_ch
		fqs_ch
	main:
		pilon1_ch = PILON_POLISH_ROUND1(
			flye_medaka_ch.map({meta,asm -> [meta,asm/'02_medaka/consensus.fasta']}),
			fqs_ch
		)
		pilon2_ch = PILON_POLISH_ROUND2(
			pilon1_ch.map({meta,asm -> [meta,asm/'pilon.fasta']}),
			fqs_ch
		)
		pilon3_ch = PILON_POLISH_ROUND3(
			pilon2_ch.map({meta,asm -> [meta,asm/'pilon.fasta']}),
			fqs_ch
		)
		HYBRID_FLYE_MEDAKA_PILON_FOLDER(flye_medaka_ch.join(pilon1_ch).join(pilon2_ch).join(pilon3_ch))
	emit:
		HYBRID_FLYE_MEDAKA_PILON_FOLDER.out
}

workflow ASSEMBLE_READS {
	take:
		fql_ch    // channel: [ val(meta), path(long_reads) ]
		fqs_ch    // channel: [ val(meta), path(short_reads) ]
	main:
		// Short reads only assemblies
		SHORT_SPADES(
			fqs_ch
				.filter({params.short_spades})
				.map({meta,fqs -> [meta,fqs,[]]})
		)
		SHORT_UNICYCLER(
			fqs_ch
				.filter({params.short_unicycler})
				.map({meta,fqs -> [meta,fqs,[]]})
		)
		
		// Long reads only assemblies
		LONG_FLYE_MEDAKA(
			fql_ch
				.filter({params.long_flye_medaka|params.hybrid_flye_medaka_pilon})
		)
		LONG_HYBRACTER(
			fql_ch
				.filter({params.long_hybracter})
				.map({meta,fql -> [meta,[],fql]})
		)
		LONG_UNICYCLER(
			fql_ch
				.filter({params.long_unicycler})
				.map({meta,fql -> [meta,[],fql]})
		)

		// Hybrid assemblies
		HYBRID_HYBRACTER(
			fql_ch.join(fqs_ch)
				.filter({params.hybrid_hybracter})
				.map({meta,fql,fqs -> [meta,fqs,fql]})
		)
		HYBRID_UNICYCLER(
			fql_ch.join(fqs_ch)
				.filter({params.hybrid_unicycler})
				.map({meta,fql,fqs -> [meta,fqs,fql]})
		)
		HYBRID_FLYE_MEDAKA_PILON(
			LONG_FLYE_MEDAKA.out,
			fqs_ch.filter({params.hybrid_flye_medaka_pilon})
		)

		// TODO: Run assemblies individual QC
		// TODO: Run QC summary report
	emit:
		short_spades     = SHORT_SPADES.out
		short_unicycler  = SHORT_UNICYCLER.out
		
		long_flye_medaka = LONG_FLYE_MEDAKA.out
		long_unicycler   = LONG_UNICYCLER.out
		long_hybracter   = LONG_HYBRACTER.out
		
		hybrid_unicycler = HYBRID_UNICYCLER.out
		hybrid_hybracter = HYBRID_HYBRACTER.out
		hybrid_flye_medaka_pilon = HYBRID_FLYE_MEDAKA_PILON.out
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
				
		// Reads processing
		//LONG_READS(ss.lr_ch)
		//SHORT_READS(ss.sr_ch)
		
		// Reads assembly
		ASSEMBLE_READS(ss.lr_ch,ss.sr_ch)
		//ASSEMBLY_QC(ss.asm_ch,ss.lr_ch,ss.sr_ch)

		// MultiQC
		/*
		ORGANIZE_FILES(
			Channel.empty().mix(
				ASSEMBLY_QC.out.long_bam_stats.map({meta,file -> [file,"${meta.sample_id}_long.bam.stats"]}),
				ASSEMBLY_QC.out.short_bam_stats.map({meta,file -> [file,"${meta.sample_id}_short.bam.stats"]}),
				LONG_READS.out.nanostat.map({meta,file -> [file,"${meta.sample_id}_long.nanostat"]}),
				SHORT_READS.out.fastqc_zip.map({meta,files -> [files[0],"${meta.sample_id}_short_fastqc.zip"]}),
				SHORT_READS.out.fastqc_zip.map({meta,files -> [files[1],"${meta.sample_id}_short_R2_fastqc.zip"]})
			)
			.collect({[it]})
			.map({["unused",it]})
		)
		MULTIQC(ORGANIZE_FILES.out,file("${moduleDir}/assets/multiqc/config.yml"))
		*/

	publish:
		// Input assembly QC
/*		
    	long_bam           = ASSEMBLY_QC.out.long_bam
    	long_bai           = ASSEMBLY_QC.out.long_bai
    	long_bam_stats     = ASSEMBLY_QC.out.long_bam_stats
		short_bam          = ASSEMBLY_QC.out.short_bam
		short_bai          = ASSEMBLY_QC.out.short_bai
		short_bam_stats    = ASSEMBLY_QC.out.short_bam_stats
		assembly_qc_html   = ASSEMBLY_QC.out.html
*/
		// Reads QC
/*		
		long_qc             = LONG_READS.out.nanoplot
		short_qc            = SHORT_READS.out.fastqc_html
*/			
		// Assemblies
		long_flye_medaka         = ASSEMBLE_READS.out.long_flye_medaka
		long_unicycler           = ASSEMBLE_READS.out.long_unicycler
		long_hybracter           = ASSEMBLE_READS.out.long_hybracter
		short_spades             = ASSEMBLE_READS.out.short_spades
		short_unicycler          = ASSEMBLE_READS.out.short_unicycler
		hybrid_unicycler         = ASSEMBLE_READS.out.hybrid_unicycler
		hybrid_hybracter         = ASSEMBLE_READS.out.hybrid_hybracter
		hybrid_flye_medaka_pilon = ASSEMBLE_READS.out.hybrid_flye_medaka_pilon
			
		// Summary reports
    	multiqc          = Channel.empty()//MULTIQC.out.html
}
