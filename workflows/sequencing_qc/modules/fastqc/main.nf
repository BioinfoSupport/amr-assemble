process FASTQC {
    container 'quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0'
    cpus 3
    memory '5 GB'
    time '1h'
    ext.args = ''
    input:
	    tuple val(meta), path(reads)
    output:
	    tuple val(meta), path("*_fastqc.html"), emit: html
	    tuple val(meta), path("*_fastqc.zip"), emit: zip
    script:
	    """
	    gzip -dc ${reads} | gzip > ${meta.sample_id}.fastq.gz
	    fastqc \\
	        ${task.ext.args} \\
	        --threads ${task.cpus} \\
	        --memory 5000 \\
	        ${meta.sample_id}.fastq.gz
	    rm ${meta.sample_id}.fastq.gz
	    """
	  stub:
	  	"""
	  	touch ${meta.sample_id}_fastqc.html
	  	touch ${meta.sample_id}_fastqc.zip
	  	"""
}