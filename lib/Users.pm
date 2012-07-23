package Users;

use strict;
use warnings;

sub apipe_ignore {
    return qw(
        adukes
        ccarey
        coliver
        eclark
        edemello
        ehvatum
        iferguso
        josborne
        jkoval
        jpeck
        jschindl
        lcarmich
        mjohnson
        pkimmey
        rhancock
        rlong
        rmeyer
        swallace
        tdutton
    );
}

sub apipe { 
    return qw(
        abrummet
        acoffman
        aregier
        boberkfe
        dmorton
        ebelter
        fdu
        gsanders
        jlolofie
        jmcmicha
        jweible
        kkyung
        mburnett
        nnutter
        tabbott
        tmooney
    );
}

sub reference_alignment {
    return qw(
        boberkfe
        fdu
        tmooney
    );
}

sub somatic_variation {
    return qw(
        fdu
        gsanders
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

sub gene_prediction_eukaryotic {
    return qw(
        ssurulir
        xzhang
    );
}

1;

