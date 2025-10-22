process HYBRACTER_ADAPT {
  input:
      tuple val(meta), path('hybracter')
  output:
      tuple val(meta), path('assembly.fasta'), emit:fasta
	script:
	"""
	"""
} 