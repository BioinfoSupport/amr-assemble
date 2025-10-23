
include { HYBRACTER   } from './modules/hybracter'
include { HYBRACTER_ADAPT } from './modules/hybracter/adapt'

workflow HYBRID_HYBRACTER {
	take:
	  fql_ch
		fqs_ch
	main:
		HYBRACTER(fqs_ch.join(fql_ch)) | HYBRACTER_ADAPT
	emit:
		fasta = HYBRACTER_ADAPT.out.fasta
		dir   = HYBRACTER.out
}

workflow LONG_HYBRACTER {
	take:
		fql_ch
	main:
		HYBRACTER(fql_ch.map({meta,fql -> [meta,[],fql]})) | HYBRACTER_ADAPT
	emit:
		fasta = HYBRACTER_ADAPT.out.fasta
		dir   = HYBRACTER.out
}

