package Users;

use strict;
use warnings;

# When someone is removed from LDAP then their email address becomes
# invalid. If we try to send notifications and their email address is
# included then the notification just gets dropped without any error.
# So we have to add people to this ignore list to prevent that.
sub apipe_ignore {
    return qw(
        adukes
        ccarey
        cfederer
        coliver
        eclark
        edemello
        ehvatum
        gsanders
        josborne
        jkoval
        jlolofie
        jpeck
        jschindl
        lcarmich
        mburnett
        mjohnson
        nnutter
        pkimmey
        rhancock
        rlong
        rmeyer
        swallace
        tabbott
        tdutton
    );
}

# This list is used to identify "real" APipe members in the sense that
# we can be sure some APipe members is always responsible for a test
# failure. This should be the LDAP group minus a few individuals, e.g.
# ssmith, jeldred, and Systems guys.
sub apipe { 
    return qw(
        abrummet
        acoffman
        aregier
        dmorton
        ebelter
        fdu
        iferguso
        jmcmicha
        jweible
        kkyung
        mfulton
        mkiwala
        ssiebert
        tmooney
    );
}

sub reference_alignment {
    return qw(
        fdu
        tmooney
    );
}

sub somatic_variation {
    return qw(
        fdu
        tmooney
    );
}

sub somatic {
    return qw(
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
        kpepin
        xzhang
        tmooney
    );
}

sub clin_seq {
    return qw(
        aramu
        awagner
        bainscou
        mgriffit
        ogriffit
    );
}

1;

