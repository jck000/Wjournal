package Wjournal::Schema::ResultSet::Comment;

use strict;
use warnings;

use base qw/DBIx::Class::ResultSet/;

use POSIX 'strftime';

sub get_rendered {
    my ($self, %params) = @_;
    my $date_format = $params{'date_format'} || "%a, %d %b %Y %H:%M";

    my @rendered_comments;

    while (my $comment = $self->next) {
        push @rendered_comments, {
           id => $comment->id,
           name => $comment->render_name,
           website => $comment->render_website,
           two_cents => $comment->render_two_cents,
           stamp => strftime($date_format, localtime($comment->date)),
           gravatar => $comment->gravatar,
        }
    }

    return (@rendered_comments) ? \@rendered_comments : undef;
}

sub approved {
    shift->search_rs({ approved => 1 });
}

1;

