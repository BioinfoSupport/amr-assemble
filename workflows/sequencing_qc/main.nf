
include { NANOPLOT                            } from './modules/nanoplot'
include { FASTQC                              } from './modules/fastqc'
include { validateParameters; paramsSummaryLog; samplesheetToList } from 'plugin/nf-schema'


process ORGANIZE_FILES {
    input:
    	tuple(val(meta),val(file_pairs)) // liste de [[path(src), target]]
    output:
    	tuple(val(meta),path("output",type:'dir'))
    script:
    	def cmd = file_pairs
    		.findAll({src,target -> src})
    		.collect({src,target ->
			    def dest_path = "output/${target}"
			    return "mkdir -p \$(dirname ${dest_path}) && ln -s ${src} ${dest_path}".stripIndent()
    	})
    """
    mkdir -p output
    ${cmd.join('\n')}
    """
}


workflow SEQUENCING_QC {
	take:
		fql_ch    // channel: [ val(meta), path(long_reads) ]
		fqs_ch    // channel: [ val(meta), path(short_reads) ]
	main:
		// Reads Quality Controls
		NANOPLOT(fql_ch)
		FASTQC(fqs_ch)
		
		ORGANIZE_FILES(
			Channel.empty().mix(
				FASTQC.out.html.map({meta,files -> files.withIndex().collect({f,i -> [f,"samples/${meta.sample_id}/short_reads/fastqc_read${i+1}.html"]})}),
				NANOPLOT.out.nanoplot.map({meta,file -> [[file,"samples/${meta.sample_id}/long_reads/nanoplot"]]})
			)
			.collect({it})
			.map({["sequencing_qc",it]})
		)

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

	emit:
		long_nanoplot = NANOPLOT.out.nanoplot
		long_nanostat = NANOPLOT.out.nanostat
		short_fastqc_html = FASTQC.out.html
		short_fastqc_zip  = FASTQC.out.zip
		qc = ORGANIZE_FILES.out
}


