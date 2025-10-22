
include { UNICYCLER_RUN   } from './modules/unicycler/run'
include { UNICYCLER_ADAPT } from './modules/unicycler/adapt'

workflow HYBRID_UNICYCLER {
	take:
	  fql_ch
		fqs_ch
	main:
		UNICYCLER_RUN(fqs_ch.join(fql_ch)) | UNICYCLER_ADAPT
	emit:
		fasta = UNICYCLER_ADAPT.out.fasta
		dir   = UNICYCLER_RUN.out
}

workflow SHORT_UNICYCLER {
	take:
		fqs_ch
	main:
		UNICYCLER_RUN(fqs_ch.map({meta,fqs -> [meta,fqs,[]]})) | UNICYCLER_ADAPT
	emit:
		fasta = UNICYCLER_ADAPT.out.fasta
		dir   = UNICYCLER_RUN.out
}

workflow LONG_UNICYCLER {
	take:
		fql_ch
	main:
		UNICYCLER_RUN(fql_ch.map({meta,fql -> [meta,[],fql]})) | UNICYCLER_ADAPT
	emit:
		fasta = UNICYCLER_ADAPT.out.fasta
		dir   = UNICYCLER_RUN.out
}

