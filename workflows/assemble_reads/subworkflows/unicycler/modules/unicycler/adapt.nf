process UNICYCLER_ADAPT {
  input:
      tuple val(meta), path('unicycler')
  output:
      tuple val(meta), path('assembly.fasta'), emit:fasta
	script:
	"""
			cp unicycler/assembly.fasta assembly.fasta
	"""
}