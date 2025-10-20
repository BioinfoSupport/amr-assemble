

include { UNICYCLER    as LONG_UNICYCLER      } from './modules/unicycler'
include { UNICYCLER    as SHORT_UNICYCLER     } from './modules/unicycler'
include { UNICYCLER    as HYBRID_UNICYCLER    } from './modules/unicycler'
include { HYBRACTER    as LONG_HYBRACTER      } from './modules/hybracter'
include { HYBRACTER    as HYBRID_HYBRACTER    } from './modules/hybracter'
include { SPADES       as SHORT_SPADES        } from './modules/spades'
include { FLYE_MEDAKA  as LONG_FLYE_MEDAKA    } from './subworkflows/flye_medaka'
include { PILON_POLISH as PILON_POLISH_ROUND1 } from './subworkflows/pilon_polish'
include { PILON_POLISH as PILON_POLISH_ROUND2 } from './subworkflows/pilon_polish'
include { PILON_POLISH as PILON_POLISH_ROUND3 } from './subworkflows/pilon_polish'
include { validateParameters; paramsSummaryLog; samplesheetToList } from 'plugin/nf-schema'



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
		flye_medaka_ch
		fqs_ch
	main:
		pilon1_ch = PILON_POLISH_ROUND1(
			flye_medaka_ch.map({meta,asm -> [meta,asm/'02_medaka/consensus.fasta']}),
			fqs_ch
		)
		pilon2_ch = PILON_POLISH_ROUND2(
			pilon1_ch.map({meta,asm -> [meta,asm/'pilon.fasta']}),
			fqs_ch
		)
		pilon3_ch = PILON_POLISH_ROUND3(
			pilon2_ch.map({meta,asm -> [meta,asm/'pilon.fasta']}),
			fqs_ch
		)
		HYBRID_FLYE_MEDAKA_PILON_FOLDER(flye_medaka_ch.join(pilon1_ch).join(pilon2_ch).join(pilon3_ch))
	emit:
		HYBRID_FLYE_MEDAKA_PILON_FOLDER.out
}

workflow ASSEMBLE_READS {
	take:
		opts
		fql_ch    // channel: [ val(meta), path(long_reads) ]
		fqs_ch    // channel: [ val(meta), path(short_reads) ]
	main:
		// Short reads only assemblies
		SHORT_SPADES(
			fqs_ch
				.filter({opts.short_spades})
				.map({meta,fqs -> [meta,fqs,[]]})
		)
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
			LONG_FLYE_MEDAKA.out,
			fqs_ch.filter({opts.hybrid_flye_medaka_pilon})
		)
		
	emit:
		assemblies = Channel.empty().mix(
			SHORT_SPADES.out.map({meta,dir -> [meta,[assembly_name:'short_spades'],dir,dir / 'scaffolds.fasta',null]}),
			SHORT_UNICYCLER.out.map({meta,dir -> [meta,[assembly_name:'short_unicycler'],dir,dir / 'assembly.fasta',null]}),
			LONG_FLYE_MEDAKA.out.map({meta,dir -> [meta,[assembly_name:'long_flye_medaka'],dir,dir / '02_medaka/consensus.fasta',null]}),
			LONG_UNICYCLER.out.map({meta,dir -> [meta,[assembly_name:'long_unicycler'],dir,dir / 'assembly.fasta',null]}),
			LONG_HYBRACTER.out.map({meta,dir -> [meta,[assembly_name:'long_hybracter'],dir,dir / 'assembly.fasta',null]}),
		  HYBRID_UNICYCLER.out.map({meta,dir -> [meta,[assembly_name:'hybrid_unicycler'],dir,dir / 'assembly.fasta',null]}),
		  HYBRID_HYBRACTER.out.map({meta,dir -> [meta,[assembly_name:'hybrid_hybracter'],dir,dir / 'assembly.fasta',null]}),
		  HYBRID_FLYE_MEDAKA_PILON.out.map({meta,dir -> [meta,[assembly_name:'hybrid_flye_medaka_pilon'],dir,dir / '05_pilon_round3/pilon.fasta',null]})
		)
}

