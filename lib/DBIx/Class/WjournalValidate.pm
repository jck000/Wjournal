package DBIx::Class::WjournalValidate;

use strict;
use warnings;

use base qw/DBIx::Class/;

=head1 NAME

DBIx::Class::WjournalValidate - DBIx::Class component used by L<Wjournal> to dispatch validation to custom Schema subs.

=head1 SYNOPSIS

  __PACKAGE__->load_components(qw/... WjournalValidate/);
  __PACKAGE__->add_columns(
    col_name => {
      col_type => 'integer',
      validate => 'validate_col'
    }
  );

  sub validate_col {
    # if success...
    return 1;
    # else
    return 0, "Optional custom error message";
  }

=cut

sub _validate_cols {
    my $self = shift;

    for my $col ($self->columns) {
        if (my $validation_sub = $self->column_info($col)->{validate}) {
            my ($success, $msg) = $self->$validation_sub($self->$col);
            ($success) || $self->throw_exception(($msg) ? '<' . $msg . '>' : "<$col failed validation>");
        }
    }
}

sub update {
    my ($self) = shift;
    $self->_validate_cols();
    return $self->next::method( @_ );
}

sub insert {
    my ($self) = shift;
    $self->_validate_cols();
    return $self->next::method( @_ );
}

1;

