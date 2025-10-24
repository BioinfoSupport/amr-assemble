

library(tidyverse)
library(Biostrings)

read_samtools_stats <- function(f) {
	if (fs::file_exists(f)) {
		stats <- readLines(f)	
	} else {
		stats <- character(0)
	}
	list(
		SN = read.table(
				text = str_subset(stats,"^SN\t"),
				sep = "\t",comment="",fill = TRUE,
				col.names = c("tag","var","value","comment")
			) |>
			mutate(var=str_replace(var,": *$","") |> make.names()) |>
			pull(value,name = var) |>
			as.list(),
		COV = read.table(
					text = str_subset(stats,"^COV\t"),
					sep = "\t",comment="",fill = TRUE,
					col.names = c("tag","range","range_max","count"),colClasses = c(tag="NULL")
				) 
	)
}

fa_extract_contigs_stats <- function(fa_file) {
	fa <- readDNAStringSet(fa_file)
	contigs <- tibble(
		contig_idx = seq_along(fa),
		contig_name = str_replace(names(fa)," .*",""),
		length = lengths(fa),
		GC_count = as.vector(Biostrings::letterFrequency(fa,"GC")),
		N_count = as.vector(Biostrings::letterFrequency(fa,"N"))
	)
	contigs
}

assembly_summary_stats <- function(contigs_stats) {
	contigs_stats |>
		summarize(
			total_len = sum(length),
			min_len = min(length),
			median_len = median(length),
			max_len = max(length),
			N50 = N50(length),
			GC_pct = sum(GC_count) / total_len
		)
}

# assembly_qc_stats <- function(fa_file,lr_stats,sr_stats) {
# 	fa_extract_contigs_stats(fa_file) |> assembly_summary_stats()
# 	
# 	stats$long_reads$SN$raw.total.sequences
# 	stats$long_reads$SN$reads.mapped / stats$long_reads$SN$raw.total.sequences
# 	stats$long_reads$SN$bases.mapped..cigar. / sum(lengths(fa)) #mean coverage
# 	stats$long_reads$COV
# 	
# 	stats$short_reads$SN$raw.total.sequences
# 	stats$short_reads$SN$reads.mapped / stats$short_reads$SN$raw.total.sequences
# 	stats$short_reads$SN$bases.mapped..cigar. / sum(lengths(fa))
# 	stats$short_reads$COV
# 	
# 	
# 	stats <- list(
# 		long_reads = read_samtools_stats(fs::path(params$isolate_dir,"long_reads.cram.stats")),
# 		short_reads = read_samtools_stats(fs::path(params$isolate_dir,"short_reads.cram.stats"))
# 	)
# }
