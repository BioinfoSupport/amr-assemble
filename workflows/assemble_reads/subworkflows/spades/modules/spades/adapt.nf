process SPADES_ADAPT {
  input:
      tuple val(meta), path('spades')
  output:
      tuple val(meta), path('assembly.fasta'), emit:fasta
	script:
	"""
		if [ -f spades/scaffolds.fasta ]; then
			cp spades/scaffolds.fasta assembly.fasta
		else
			cp spades/contigs.fasta assembly.fasta
		fi
	"""
} 