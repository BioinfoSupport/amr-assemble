
include { HYBRACTER_RUN   } from './modules/hybracter/run'
include { HYBRACTER_ADAPT } from './modules/hybracter/adapt'

workflow HYBRID_HYBRACTER {
	take:
	  fql_ch
		fqs_ch
	main:
		HYBRACTER_RUN(fqs_ch.join(fql_ch)) | HYBRACTER_ADAPT
	emit:
		fasta = HYBRACTER_ADAPT.out.fasta
		dir   = HYBRACTER_RUN.out
}

workflow LONG_HYBRACTER {
	take:
		fql_ch
	main:
		HYBRACTER_RUN(fql_ch.map({meta,fql -> [meta,[],fql]})) | HYBRACTER_ADAPT
	emit:
		fasta = HYBRACTER_ADAPT.out.fasta
		dir   = HYBRACTER_RUN.out
}

