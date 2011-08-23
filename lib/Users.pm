package Users;

use strict;
use warnings;

sub apipe_ignore {
    return qw(
        lcarmich
        jpeck
        pkimmey
        ehvatum
        josborne
        mjohnson
        edemello
        rmeyer
        jschindl
        ccarey
        eclark
        tdutton
        iferguso
        coliver
    );
}

sub apipe { 
    return qw(
        abrummet
        adukes
        bdericks
        boberkfe
        ebelter
        fdu
        gsanders
        jkoval
        jlolofie
        jmcmicha
        jweible
        kkyung
        nnutter
        rhancock
        rlong
        swallace
        tabbott
        tmooney
    );
}

sub reference_alignment {
    return qw(
        bdericks
        boberkfe
        fdu
        tmooney
    );
}

sub somatic_variation {
    return qw(
        adukes
        gsanders
        rlong
    );
}

sub somatic {
    return qw(
        gsanders
        tmooney
    );
}

sub de_novo_assembly {
    return qw(
        ebelter
        kkyung
    );
}

sub amplicon_assembly {
    return qw(
        ebelter
        kkyung
    );
}

sub convergence {
    return qw(
        tmooney
    );
}

sub metagenomic_composition_16s {
    return qw(
        ebelter
        kkyung
    );
}

1;

