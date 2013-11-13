package Wjournal::Schema::Result::Post;

use strict;
use warnings;

use base qw/DBIx::Class::Core/;

use HTML::Entities;
use HTML::TreeBuilder;
use Text::Markdown 'markdown';
use v5.10.1;

# Making changes? Don't forget to increment $VERSION in Wjournal::Schema

__PACKAGE__->load_components(qw/WjournalValidate/);

__PACKAGE__->table('post');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_nullable       => 0,
        is_auto_increment => 1
    },
    uid => {
        data_type => 'integer',
    },
    format => {
        data_type => 'varchar',
        size      => 8
    },
    is_pending => {
        data_type     => 'integer',
        default_value => 1,
    },
    is_deleted => {
        data_type     => 'integer',
        is_nullable   => 1,
        default_value => 0,
    },
    disable_comment => {
        data_type     => 'integer',
        is_nullable   => 1,
        default_value => 0,
    },
    preview_token => {
        data_type => 'char',
        size      => 36
    },
    published_date => {
        data_type   => 'integer',
        is_nullable => 0
    },
    subject => {
        data_type => 'text',
        validate  => 'validate_subject',
    },
    text => {
        data_type => 'text',
        validate  => 'validate_text',
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('poster', 'Wjournal::Schema::Result::Poster', 'uid');
__PACKAGE__->has_many('comments', 'Wjournal::Schema::Result::Comment', 'post_id');

sub new {
    my ($self, $attrs) = @_;
    $attrs->{'is_pending'} ||= 1;
    $attrs->{'is_deleted'} ||= 0;
    return $self->next::method($attrs);
}

sub render_text {
    my ($self) = @_;
    for ($self->format) {
        when ('txt') {
            my $txt = '<p>' . encode_entities($self->text, '<>&\'"') . '</p>';
            $txt =~ s#\n\s*\n#</p><p>#g;
            Wjournal::linkify(\$txt);
            return $txt;
        }
        when ('markdown') {
            return markdown($self->text);
        }
    }
    return $self->text;
}

sub validate_subject {
    my ($self) = @_;

    return 0, "Newline in subject" if $self->subject =~ /[\r\n]/;

    1;
}

sub validate_text {
    my ($self) = @_;
    return 1 if $self->format !~ /html/i;

    # This serves nicely to close hanging open tags.
    my $tree = HTML::TreeBuilder->new();
    $tree->parse($self->text);
    $tree->eof();
    $self->text($tree->guts(0)->as_HTML);
}

sub publish {
    my ($self) = @_;

    return 1 if ($self->is_pending == 0);

    my $time = $self->published_date || time;
    return $self->update(
        {   is_pending => 0,
            published_date => $time,
        }
    );

    0;
}

1;

