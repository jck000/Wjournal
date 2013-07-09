package Wjournal::Schema::Result::Poster;

use strict;
use warnings;

use base qw/DBIx::Class::Core/;

# Making changes? Don't forget to increment $VERSION in Wjournal::Schema

__PACKAGE__->load_components(qw/WjournalValidate/);

__PACKAGE__->table('poster');

__PACKAGE__->add_columns(
    uid => {
        data_type   => 'integer',
        is_nullable => 0,
    },
    admin => {
        data_type   => 'integer',
    },
    login => {
        data_type => 'varchar',
        size      => 14
    },
    name => {
        data_type => 'varchar',
        size      => 20
    }
);

__PACKAGE__->set_primary_key('uid');
__PACKAGE__->has_many('posts', 'Wjournal::Schema::Result::Post', 'uid');

1;

