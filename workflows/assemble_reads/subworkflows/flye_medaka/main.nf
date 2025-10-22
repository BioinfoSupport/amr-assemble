
include { FLYE             } from './modules/flye'
include { MEDAKA_CONSENSUS } from './modules/medaka/consensus'

process OUTPUT_FOLDER {
    input:
    	tuple val(meta),path('flye_medaka/01_flye'),path('flye_medaka/02_medaka'),path('assembly.fasta')
    output:
    	tuple val(meta),path("flye_medaka",type: 'dir'), emit: dir
			tuple val(meta), path('assembly.fasta'), emit: fasta
    script:
    """
    """
}

workflow FLYE_MEDAKA {
	take:
		fql_ch
	main:
		FLYE(fql_ch).fasta
			.join(fql_ch)
			| MEDAKA_CONSENSUS
		OUTPUT_FOLDER(FLYE.out.dir
			.join(MEDAKA_CONSENSUS.out.dir)
			.join(MEDAKA_CONSENSUS.out.fasta)
		)
	emit:
		dir   = OUTPUT_FOLDER.out.dir 
		fasta = OUTPUT_FOLDER.out.fasta
}



