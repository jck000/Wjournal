package Wjournal::Schema::Result::Comment;

use strict;
use warnings;

use base qw/DBIx::Class::Core/;

use HTML::Entities;
use URI::Escape;

# Making changes? Don't forget to increment $VERSION in Wjournal::Schema

__PACKAGE__->load_components(qw/WjournalValidate/);

__PACKAGE__->table('comment');

__PACKAGE__->add_columns(
    id => {
        data_type   => 'integer',
        is_nullable => 0,
        is_auto_increment => 1
    },
    post_id => {
        data_type   => 'integer'
    },
    name => {
        data_type => 'text',
        validate  => 'validate_name',
    },
    approved => {
        data_type   => 'integer',
        is_nullable => 0,
        default_value => 0
    },
    date => {
        data_type   => 'integer',
        is_nullable => 0
    },
    email => {
        data_type => 'text',
        validate  => 'validate_email',
    },
    website => {
        data_type => 'text',
        validate  => 'validate_website',
        is_nullable => 1,
    },
    two_cents => {
        data_type => 'text',
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('post', 'Wjournal::Schema::Result::Post', 'post_id');

sub render_website {
    my ($self) = @_;
    my $uri = URI->new($self->website)->as_string;
    $uri =~ s/'/%27/; # Why doesn't URI encode apostrophes? Should we be using something more markup oriented?
    return $uri;
}

sub render_name {
    my ($self) = @_;
    return encode_entities($self->name, '<>&\'"');
}

sub render_email {
    my ($self) = @_;
    return encode_entities($self->email, '<>&\'"');
}

sub render_two_cents {
    my ($self) = @_;
    my $two_cents = encode_entities($self->two_cents, '<>&\'"');
    $two_cents =~ s#\n#<br />#g;
    Wjournal::linkify(\$two_cents);
    return $two_cents;
}

# RFC 2822 validation is non-trivial, let's just check for at least one
# '@' and no newlines.
sub validate_email {
    my ($self) = @_;

    return 0, "We need an email address" if (!$self->email);
    return 0, "Newline in email address" if $self->email =~ /[\r\n]/;
    return 0, "No '\@' in email address" if $self->email !~ /@/;

    1;
}

sub validate_website {
    my ($self) = @_;

    return 1 if (!$self->website);

    $self->website('http://' . $self->website) if $self->website !~ /^https?:\/\//i;

    return 0, "Newline in website" if $self->website =~ /[\r\n]/;

    1;
}

# Well, I hope this doesn't result in accusations of ethnocentrism, but
# no newlines in the name here!
# Also, if we get one, the form has been diddled.
sub validate_name {
    my ($self) = @_;

    return 0, "We need a name" if (!$self->name);
    return 0, "Newline in name" if $self->name =~ /[\r\n]/;

    1;
}

1;

