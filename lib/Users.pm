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
        coliver
        eclark
        edemello
        ehvatum
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

# This list is used to identify "real" APipe members in the sense that
# we can be sure some APipe members is always responsible for a test
# failure. This should be the LDAP group minus a few individuals, e.g.
# ssmith, jeldred, and Systems guys.
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
        iferguso
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

