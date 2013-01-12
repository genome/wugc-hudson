package GenomeCI::Schema::Result::BlessedBuild;
use base qw(DBIx::Class::Core);

__PACKAGE__->table('BlessedBuild');
__PACKAGE__->add_columns(qw(model_id perl_version git_revision username));
__PACKAGE__->set_primary_key(qw(model_id perl_version));

1;
