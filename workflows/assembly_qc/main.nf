
include { MINIMAP2_ALIGN_ONT } from './modules/minimap2/align_ont'
include { SAMTOOLS_STATS as SAMTOOLS_STATS_LONG  } from './modules/samtools/stats'
include { SAMTOOLS_STATS as SAMTOOLS_STATS_SHORT } from './modules/samtools/stats'
include { BWA_MEM            } from './modules/bwa/mem'
include { BWA_INDEX          } from './modules/bwa/index'
include { ORGANIZE_FILES     } from './modules/organize_files'
//include { RMD_RENDER         } from './modules/rmd/render'



/* Assembly stats
Short Reads
  - % mapped
  - % properly paired
  - Avg coverage
  - Number chimeric pair
  - Number of identified mutation in the VCF
Long Reads
  - % mapped
  - Avg coverage
  - Number of identified mutation in the VCF
*/

/* Contigs stats
Short Reads
  - % mapped
  - % properly paired
  - Avg coverage
Long Reads
  - % mapped
  - Avg coverage
*/

/* Report
Short Reads
   - inter contigs links
*/


/*
process IGV_SCRIPT {
	input:
	  val(meta)
  output:
    tuple val(meta), path("load_in_igv.sh")
	script:
	"""
	file("${moduleDir}/assets/load_in_igv.sh")
	"""
}
*/


process ASSEMBLY_QC_STATS {
	  container "registry.gitlab.unige.ch/amr-genomics/rscript:main"
    memory '8 GB'
    cpus 2
    time '30 min'
    input:
    		tuple val(meta), path("stats")
    		path("assets") 
    output:
        tuple val(meta), path('contigs_qc.tsv'), emit:'contigs_qc_tsv'
        tuple val(meta), path('assembly_qc.tsv'), emit:'assembly_qc_tsv'
    script:
				"""
				#!/usr/bin/env Rscript
				source("assets/lib_assembly_stats.R")
				contigs <- fa_extract_contigs_stats("stats/assembly.fasta") 
				contigs |> write_tsv("contigs_qc.tsv")
				contigs |> assembly_summary_stats() |> write_tsv("assembly_qc.tsv")
				"""
}



workflow ASSEMBLY_QC {
	take:
		fa_ch
		fqs_ch
		fql_ch
	main:
			// Short reads alignment and statistics
			BWA_MEM(BWA_INDEX(fa_ch).join(fqs_ch))
			SAMTOOLS_STATS_SHORT(BWA_MEM.out.bam)
			
			// Long reads alignment and statistics
			MINIMAP2_ALIGN_ONT(fa_ch.join(fql_ch))
			SAMTOOLS_STATS_LONG(MINIMAP2_ALIGN_ONT.out.bam)
			
			//TODO: RUN VCF_LONG
			//TODO: RUN VCF_SHORT
			//TODO: HTML_AND_JSON_QC_REPORT()
			fa_ch
				.join(SAMTOOLS_STATS_LONG.out,remainder:true)
				.join(SAMTOOLS_STATS_SHORT.out,remainder:true)
				.map({meta,x1,x2,x3 -> [meta,[[x1,"assembly.fasta"],[x2,"long_reads.bam.stats"],[x3,"short_reads.bam.stats"]].findAll({x,y -> x})]})
				| ORGANIZE_FILES
			
			ASSEMBLY_QC_STATS(ORGANIZE_FILES.out,"${moduleDir}/assets")
			
			/*	
			RMD_RENDER(
				ORGANIZE_FILES.out.map({m,x -> [m,x,"isolate_dir='${x}'"]}),
				file("${moduleDir}/assets/isolate_assembly_qc.Rmd"),
				file("${moduleDir}/assets/isolate_assembly_qc.Rmd")
			)
			*/
			
			//TODO: CHARACTERIZE_UNMAPPED_READS
			//TODO: QC_AGGREGATOR
	emit:
		long_bam        = MINIMAP2_ALIGN_ONT.out.bam
		long_bai        = MINIMAP2_ALIGN_ONT.out.bai
		long_bam_stats  = SAMTOOLS_STATS_LONG.out
		long_vcf        = Channel.empty()
		
		short_bam       = BWA_MEM.out.bam
		short_bai       = BWA_MEM.out.bai
		short_bam_stats = SAMTOOLS_STATS_SHORT.out
		short_vcf       = Channel.empty()
		
		contigs_qc_tsv  = ASSEMBLY_QC_STATS.out.contigs_qc_tsv
		assembly_qc_tsv = ASSEMBLY_QC_STATS.out.assembly_qc_tsv
		//html            = RMD_RENDER.out.html
}



