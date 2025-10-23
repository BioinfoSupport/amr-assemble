
include { UNICYCLER       } from './modules/unicycler'
include { UNICYCLER_ADAPT } from './modules/unicycler/adapt'

workflow HYBRID_UNICYCLER {
	take:
	  fql_ch
		fqs_ch
	main:
		UNICYCLER(fqs_ch.join(fql_ch)) | UNICYCLER_ADAPT
	emit:
		fasta = UNICYCLER_ADAPT.out.fasta
		dir   = UNICYCLER.out
}

workflow SHORT_UNICYCLER {
	take:
		fqs_ch
	main:
		UNICYCLER(fqs_ch.map({meta,fqs -> [meta,fqs,[]]})) | UNICYCLER_ADAPT
	emit:
		fasta = UNICYCLER_ADAPT.out.fasta
		dir   = UNICYCLER.out
}

workflow LONG_UNICYCLER {
	take:
		fql_ch
	main:
		UNICYCLER(fql_ch.map({meta,fql -> [meta,[],fql]})) | UNICYCLER_ADAPT
	emit:
		fasta = UNICYCLER_ADAPT.out.fasta
		dir   = UNICYCLER.out
}

