

include { LONG_UNICYCLER                                 } from './subworkflows/unicycler'
include { SHORT_UNICYCLER                                } from './subworkflows/unicycler'
include { HYBRID_UNICYCLER                               } from './subworkflows/unicycler'
include { LONG_HYBRACTER                                 } from './subworkflows/hybracter'
include { HYBRID_HYBRACTER                               } from './subworkflows/hybracter'
include { SHORT_SPADES                                   } from './subworkflows/spades'
include { FLYE_MEDAKA_PILON as HYBRID_FLYE_MEDAKA_PILON  } from './subworkflows/flye_medaka_pilon'


workflow ASSEMBLE_READS {
	take:
		opts
		fql_ch    // channel: [ val(meta), path(long_reads) ]
		fqs_ch    // channel: [ val(meta), path(short_reads) ]
	main:
		// Short reads only assemblies
		SHORT_SPADES(fqs_ch.filter({opts.short_spades}))
		SHORT_UNICYCLER(fqs_ch.filter({opts.short_unicycler}))
		
		// Long reads only assemblies
		LONG_HYBRACTER(fql_ch.filter({opts.long_hybracter}))
		LONG_UNICYCLER(fql_ch.filter({opts.long_unicycler}))

		// Hybrid assemblies
		HYBRID_HYBRACTER(fql_ch.filter({opts.hybrid_unicycler}),fqs_ch)
		HYBRID_UNICYCLER(fql_ch.filter({opts.hybrid_unicycler}),fqs_ch)
		HYBRID_FLYE_MEDAKA_PILON(
			fql_ch.filter({opts.long_flye_medaka|opts.hybrid_flye_medaka_pilon}),
			fqs_ch.filter({opts.hybrid_flye_medaka_pilon})
		)
	emit:
		fasta = Channel.empty().mix(
			SHORT_SPADES.out.fasta.map({meta,x -> [meta,[assembly_name:'short_spades'],x]}),
			SHORT_UNICYCLER.out.fasta.map({meta,x -> [meta,[assembly_name:'short_unicycler'],x]}),
			//LONG_FLYE_MEDAKA.out.fasta.map({meta,x -> [meta,[assembly_name:'long_flye_medaka'],x]}),
			LONG_UNICYCLER.out.fasta.map({meta,x -> [meta,[assembly_name:'long_unicycler'],x]}),
			LONG_HYBRACTER.out.fasta.map({meta,x -> [meta,[assembly_name:'long_hybracter'],x]}),
		  HYBRID_UNICYCLER.out.fasta.map({meta,x -> [meta,[assembly_name:'hybrid_unicycler'],x]}),
		  HYBRID_HYBRACTER.out.fasta.map({meta,x -> [meta,[assembly_name:'hybrid_hybracter'],x]}),
		  HYBRID_FLYE_MEDAKA_PILON.out.fasta.map({meta,x -> [meta,[assembly_name:'hybrid_flye_medaka_pilon'],x]})
		)
		dir = Channel.empty().mix(
			SHORT_SPADES.out.dir.map({meta,x -> [meta,[assembly_name:'short_spades'],x]}),
			SHORT_UNICYCLER.out.dir.map({meta,x -> [meta,[assembly_name:'short_unicycler'],x]}),
			//LONG_FLYE_MEDAKA.out.dir.map({meta,x -> [meta,[assembly_name:'long_flye_medaka'],x]}),
			LONG_UNICYCLER.out.dir.map({meta,x -> [meta,[assembly_name:'long_unicycler'],x]}),
			LONG_HYBRACTER.out.dir.map({meta,x -> [meta,[assembly_name:'long_hybracter'],x]}),
		  HYBRID_UNICYCLER.out.dir.map({meta,x -> [meta,[assembly_name:'hybrid_unicycler'],x]}),
		  HYBRID_HYBRACTER.out.dir.map({meta,x -> [meta,[assembly_name:'hybrid_hybracter'],x]}),
		  HYBRID_FLYE_MEDAKA_PILON.out.dir.map({meta,x -> [meta,[assembly_name:'hybrid_flye_medaka_pilon'],x]})
		)
}

