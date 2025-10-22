

include { UNICYCLER    as LONG_UNICYCLER      } from './modules/unicycler'
include { UNICYCLER    as SHORT_UNICYCLER     } from './modules/unicycler'
include { UNICYCLER    as HYBRID_UNICYCLER    } from './modules/unicycler'
include { HYBRACTER    as LONG_HYBRACTER      } from './modules/hybracter'
include { HYBRACTER    as HYBRID_HYBRACTER    } from './modules/hybracter'
include { SHORT_SPADES                        } from './subworkflows/spades'
include { FLYE_MEDAKA  as LONG_FLYE_MEDAKA    } from './subworkflows/flye_medaka'
include { PILON_POLISH as PILON_POLISH_ROUND1 } from './subworkflows/pilon_polish'
include { PILON_POLISH as PILON_POLISH_ROUND2 } from './subworkflows/pilon_polish'
include { PILON_POLISH as PILON_POLISH_ROUND3 } from './subworkflows/pilon_polish'



process HYBRID_FLYE_MEDAKA_PILON_FOLDER {
    input:
    	tuple val(meta),path('flye_medaka'),path('flye_medaka_pilon/03_pilon_round1'),path('flye_medaka_pilon/04_pilon_round2'),path('flye_medaka_pilon/05_pilon_round3')
    output:
    	tuple val(meta),path("flye_medaka_pilon",type: 'dir')
    script:
    """
    	cp --no-dereference flye_medaka/* flye_medaka_pilon/
    """
}

workflow HYBRID_FLYE_MEDAKA_PILON {
	take:
		flye_medaka_fasta_ch
		flye_medaka_dir_ch
		fqs_ch
	main:
		PILON_POLISH_ROUND1(flye_medaka_fasta_ch,fqs_ch)
		PILON_POLISH_ROUND2(PILON_POLISH_ROUND1.out.fasta,fqs_ch)
		PILON_POLISH_ROUND3(PILON_POLISH_ROUND2.out.fasta,fqs_ch)
		HYBRID_FLYE_MEDAKA_PILON_FOLDER(
			flye_medaka_dir_ch
			.join(PILON_POLISH_ROUND1.out.dir)
			.join(PILON_POLISH_ROUND2.out.dir)
			.join(PILON_POLISH_ROUND3.out.dir)
		)
	emit:
		fasta = PILON_POLISH_ROUND3.out.fasta
		dir = HYBRID_FLYE_MEDAKA_PILON_FOLDER.out
}

workflow ASSEMBLE_READS {
	take:
		opts
		fql_ch    // channel: [ val(meta), path(long_reads) ]
		fqs_ch    // channel: [ val(meta), path(short_reads) ]
	main:
		// Short reads only assemblies
		SHORT_SPADES(fqs_ch.filter({opts.short_spades}))
		SHORT_UNICYCLER(
			fqs_ch
				.filter({opts.short_unicycler})
				.map({meta,fqs -> [meta,fqs,[]]})
		)
		
		// Long reads only assemblies
		LONG_FLYE_MEDAKA(
			fql_ch
				.filter({opts.long_flye_medaka|opts.hybrid_flye_medaka_pilon})
		)
		LONG_HYBRACTER(
			fql_ch
				.filter({opts.long_hybracter})
				.map({meta,fql -> [meta,[],fql]})
		)
		LONG_UNICYCLER(
			fql_ch
				.filter({opts.long_unicycler})
				.map({meta,fql -> [meta,[],fql]})
		)

		// Hybrid assemblies
		HYBRID_HYBRACTER(
			fql_ch.join(fqs_ch)
				.filter({opts.hybrid_hybracter})
				.map({meta,fql,fqs -> [meta,fqs,fql]})
		)
		HYBRID_UNICYCLER(
			fql_ch.join(fqs_ch)
				.filter({opts.hybrid_unicycler})
				.map({meta,fql,fqs -> [meta,fqs,fql]})
		)
		HYBRID_FLYE_MEDAKA_PILON(
			LONG_FLYE_MEDAKA.out.fasta,
			LONG_FLYE_MEDAKA.out.dir,
			fqs_ch.filter({opts.hybrid_flye_medaka_pilon})
		)
		
	emit:
		fasta = Channel.empty().mix(
			SHORT_SPADES.out.fasta.map({meta,x -> [meta,[assembly_name:'short_spades'],x]}),
			SHORT_UNICYCLER.out.fasta.map({meta,x -> [meta,[assembly_name:'short_unicycler'],x]}),
			LONG_FLYE_MEDAKA.out.fasta.map({meta,x -> [meta,[assembly_name:'long_flye_medaka'],x]}),
			LONG_UNICYCLER.out.fasta.map({meta,x -> [meta,[assembly_name:'long_unicycler'],x]}),
			LONG_HYBRACTER.out.fasta.map({meta,x -> [meta,[assembly_name:'long_hybracter'],x]}),
		  HYBRID_UNICYCLER.out.fasta.map({meta,x -> [meta,[assembly_name:'hybrid_unicycler'],x]}),
		  HYBRID_HYBRACTER.out.fasta.map({meta,x -> [meta,[assembly_name:'hybrid_hybracter'],x]}),
		  HYBRID_FLYE_MEDAKA_PILON.out.fasta.map({meta,x -> [meta,[assembly_name:'hybrid_flye_medaka_pilon'],x]})
		)
		dir = Channel.empty().mix(
			SHORT_SPADES.out.dir.map({meta,x -> [meta,[assembly_name:'short_spades'],x]}),
			SHORT_UNICYCLER.out.dir.map({meta,x -> [meta,[assembly_name:'short_unicycler'],x]}),
			LONG_FLYE_MEDAKA.out.dir.map({meta,x -> [meta,[assembly_name:'long_flye_medaka'],x]}),
			LONG_UNICYCLER.out.dir.map({meta,x -> [meta,[assembly_name:'long_unicycler'],x]}),
			LONG_HYBRACTER.out.dir.map({meta,x -> [meta,[assembly_name:'long_hybracter'],x]}),
		  HYBRID_UNICYCLER.out.dir.map({meta,x -> [meta,[assembly_name:'hybrid_unicycler'],x]}),
		  HYBRID_HYBRACTER.out.dir.map({meta,x -> [meta,[assembly_name:'hybrid_hybracter'],x]}),
		  HYBRID_FLYE_MEDAKA_PILON.out.dir.map({meta,x -> [meta,[assembly_name:'hybrid_flye_medaka_pilon'],x]})
		)
}

