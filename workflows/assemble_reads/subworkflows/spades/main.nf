
include { SPADES       } from './modules/spades'
include { SPADES_ADAPT } from './modules/spades/adapt'

workflow SHORT_SPADES {
	take:
		fqs_ch
	main:
		SPADES(fqs_ch.map({meta,fqs -> [meta,fqs,[]]})) | SPADES_ADAPT
	emit:
		fasta = SPADES_ADAPT.out.fasta
		dir   = SPADES.out
}
