
include { FLYE             } from './modules/flye'
include { MEDAKA_CONSENSUS } from './modules/medaka/consensus'
include { PILON_POLISH as PILON_POLISH_ROUND1 } from './subworkflows/pilon_polish'
include { PILON_POLISH as PILON_POLISH_ROUND2 } from './subworkflows/pilon_polish'
include { PILON_POLISH as PILON_POLISH_ROUND3 } from './subworkflows/pilon_polish'


process FLYE_MEDAKA_PILON_FOLDER {
    input:
    	tuple val(meta),path('flye_medaka_pilon/01_flye'),path('flye_medaka_pilon/02_medaka'),path('flye_medaka_pilon/03_pilon_round1'),path('flye_medaka_pilon/04_pilon_round2'),path('flye_medaka_pilon/05_pilon_round3')
    output:
    	tuple val(meta),path("flye_medaka_pilon",type: 'dir')
    script:
    """
    """
}

workflow FLYE_MEDAKA_PILON {
	take:
		fql_ch
		fqs_ch
	main:
		FLYE(fql_ch).fasta.join(fql_ch) | MEDAKA_CONSENSUS
		PILON_POLISH_ROUND1(MEDAKA_CONSENSUS.out.fasta,fqs_ch)
		PILON_POLISH_ROUND2(PILON_POLISH_ROUND1.out.fasta,fqs_ch)
		PILON_POLISH_ROUND3(PILON_POLISH_ROUND2.out.fasta,fqs_ch)
		// TODO: check what happen if fqs_ch is empty
		// TODO: if fqs is empty we must return MEDAKA_CONSENSUS.out.fasta
		// TODO: if fqs is empty we must produce a folder without PILON polishing
		FLYE_MEDAKA_PILON_FOLDER(
			FLYE.out.dir
			.join(MEDAKA_CONSENSUS.out.dir)
			.join(PILON_POLISH_ROUND1.out.dir)
			.join(PILON_POLISH_ROUND2.out.dir)
			.join(PILON_POLISH_ROUND3.out.dir)
		)
	emit:
		fasta = PILON_POLISH_ROUND3.out.fasta
		dir = FLYE_MEDAKA_PILON_FOLDER.out
}
