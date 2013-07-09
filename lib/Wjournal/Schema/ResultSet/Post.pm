package Wjournal::Schema::ResultSet::Post;

use strict;
use warnings;

use base qw/DBIx::Class::ResultSet/;

use POSIX 'strftime';

sub get_rendered {
    my ($self, %params) = @_;
    my $page  = $params{'page'} || 1;
    my $rows  = $params{'rows'} || 10;
    my $date_format = $params{'date_format'} || "%a, %d %b %Y %H:%M";

    my @rendered_posts;

    delete @params{qw/date_format login page rows/};

    my $posts = ($params{'id'}) ?
        $self->verified (\%params)
    :
        $self->active->search_rs(
            \%params, {
                rows => $rows,
                page => $page,
                prefetch => [ 'poster' ],
                order_by => 'id DESC',
            }
        );

    while (my $post = $posts->next) {
        push @rendered_posts, {
            text => $post->render_text(),
            id => $post->id,
            subject => $post->subject,
            poster => $post->poster->name,
            login => $post->poster->login,
            rss_stamp => strftime("%a, %d %b %Y %H:%M:%S %z", localtime($post->published_date)),
            stamp => strftime($date_format, localtime($post->published_date)),
            comments => (($params{'id'}) ? $post->comments->approved->get_rendered( date_format => $date_format) : ()),
        };
    }

    return (@rendered_posts) ? \@rendered_posts : undef;
}

sub active {
    shift->search_rs({ is_pending => 0, is_deleted => 0 });
}

sub verified {
    my ($self, $params) = @_;
    return $self->search_rs(
        {
            -or => [
                -and => [
                    is_pending => 1,
                    preview_token => $params->{'key'}
                ],
                is_pending => 0
            ],
            'me.id' => $params->{'id'},
            is_deleted => 0
        },
        {
            #prefetch => [ 'poster', 'comments' ]
            prefetch => [ 'poster' ]
        }
    );
}

1;

