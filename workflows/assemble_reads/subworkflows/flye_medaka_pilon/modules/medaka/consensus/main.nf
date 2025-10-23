process MEDAKA_CONSENSUS {
    container 'docker.io/ontresearch/medaka:shac4e11bfa4e65668b28739ba32edc3af12baf7574-amd64'
    memory '10 GB'
    cpus 4
    time '2h'
    ext.args = '--bacteria'
    input:
        tuple val(meta), path('assembly.fasta'), path('long_reads.fastq.gz')
    output:
        tuple val(meta), path('medaka',type:'dir'), emit: dir
        tuple val(meta), path('consensus.fasta'), emit: fasta
    script:
		    """
		    medaka_consensus \\
		      ${task.ext.args} \\
			    -f -t ${task.cpus} \\
			    -d assembly.fasta \\
			    -i long_reads.fastq.gz \\
			    -o medaka
			  cp medaka/consensus.fasta ./
		    """
		stub:		    
		    """
		    mkdir -p medaka/
		    touch consensus.fasta
		    """
}
