package Wjournal::Schema;

use strict;
use warnings;

use base qw/DBIx::Class::Schema/;

# Schema version, used in database deployment
our $VERSION = 3;

__PACKAGE__->load_namespaces();
__PACKAGE__->stacktrace(0);
__PACKAGE__->load_components(qw/Schema::Versioned/);
__PACKAGE__->upgrade_directory('sql/');

1;

