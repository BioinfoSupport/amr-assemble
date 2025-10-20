
include { ORGANIZE_FILES } from './modules/organize_files'
include { NANOPLOT       } from './modules/nanoplot'
include { FASTQC         } from './modules/fastqc'
include { MULTIQC        } from './modules/multiqc'
include { validateParameters; paramsSummaryLog; samplesheetToList } from 'plugin/nf-schema'

workflow SEQUENCING_QC {
	take:
		fql_ch    // channel: [ val(meta), path(long_reads) ]
		fqs_ch    // channel: [ val(meta), path(short_reads) ]
	main:
		// Reads Quality Controls
		NANOPLOT(fql_ch)
		FASTQC(fqs_ch)

		// MultiQC
		ORGANIZE_FILES(
			Channel.empty().mix(
				NANOPLOT.out.nanostat.map({meta,file -> [file,"${meta.sample_id}.nanostat"]}),
				FASTQC.out.zip.map({meta,file -> [file,"${meta.sample_id}_fastqc.zip"]})
			)
			.collect({[it]})
			.map({["multiqc.html",it]})
		)
		MULTIQC(ORGANIZE_FILES.out,file("${moduleDir}/assets/multiqc_config.yml"))

	emit:
		long_nanoplot = NANOPLOT.out.nanoplot
		long_nanostat = NANOPLOT.out.nanostat
		short_fastqc_html = FASTQC.out.html
		short_fastqc_zip  = FASTQC.out.zip
		multiqc_html      = MULTIQC.out.html
}


