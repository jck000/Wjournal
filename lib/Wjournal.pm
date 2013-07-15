package Wjournal;

use strict;
use warnings;

use Dancer2;
use Dancer2::Plugin::DBIC 'schema';
use XML::RSS;
use Try::Tiny;
use HTML::Entities;

use Devel::Peek;

our $VERSION = '0.01';

sub db_migrate {
    my $schema         = schema('default');
    my $sql_dir        = config->{'appdir'} . '/sql';
    my $schema_version = $schema->schema_version();
    my $db_version     = $schema->get_db_version();

    $schema->upgrade_directory($sql_dir);

    if ( !( "$db_version" eq "$schema_version" ) ) {
        $schema->create_ddl_dir( undef, $schema_version, $sql_dir,
            $db_version );

        if ($db_version) {
            $schema->upgrade();
        }
        else {
            $schema->deploy();
        }
    }
}

sub linkify {
    my ($text) = @_;
    return if (!config->{'linkify'});
    $$text =~ s/(https?:\/\/[^\s]*)/<a href="$1">$1<\/a>/gi;
}

# Front page, last #posts_per_page posts from all users.

get '/' => sub {
    my $schema = schema('default');
    my $posts  = $schema->resultset('Post')->get_rendered(
        date_format => config->{'date_format'},
        rows        => config->{'posts_per_page'},
    );
    ($posts) || status 404;

    ($posts) && (my $old_link = (scalar @{$posts} >= config->{'posts_per_page'}) ?
        "/page/2" :
        undef);

    template 'index' => {
        title  => config->{'appname'},
        app    => config->{'appname'},
        byline => config->{'byline'},
        posts  => $posts || undef,
        older  => $old_link,
    };
};

# Other pages of #posts_per_page posts from all users.

get '/page/:page?' => sub {
    my $schema = schema('default');
    my $posts  = $schema->resultset('Post')->get_rendered(
        date_format => config->{'date_format'},
        rows        => config->{'posts_per_page'},
        page        => param('page')
    );
    ($posts) || status 404;

    ($posts) && (my $old_link = (scalar @{$posts} >= config->{'posts_per_page'}) ?
        "/page/" . (param('page') + 1) :
        undef);
    ($posts) && (my $new_link = (param('page') > 1) ?
        "/page/" . (param('page') - 1) :
        undef);

    template 'index' => {
        title  => config->{'appname'},
        app    => config->{'appname'},
        byline => config->{'byline'},
        posts  => $posts,
        older  => $old_link,
        newer  => $new_link,
    };
};

# Single post with preview key + rendered comments

get '/post/:post_id/:post_key?' => sub {
    my $schema = schema('default');
    my $posts  = $schema->resultset('Post')->get_rendered(
        date_format => config->{'date_format'},
        id          => param('post_id'),
        key         => param('post_key')
    );
    ($posts) || status 404;

    template 'index' => {
        title => config->{'appname'} . ' | '
          . ( ($posts) ? $posts->[0]->{'subject'} : 'Not found' ),
        app         => config->{'appname'},
        byline      => config->{'byline'},
        posts       => $posts || undef,
        commentform => template(
            'commentform' => {
                param('comment_success') ? () :
                (name => encode_entities(param('name', '<>&\'"')),
                website => encode_entities(param('website', '<>&\'"')),
                email => encode_entities(param('email', '<>&\'"')),
                two_cents => encode_entities(param('two_cents', '<>&\'"'))),
                comment_msg => param('comment_msg'),
                comment_success => param('comment_success'),
            },
            { layout => undef }
        ),
        comments => template(
            'comments' => {
                comments => $posts->[0]->{'comments'},
            },
            { layout => undef }
        ),
    };
};

# Posts for a single user, with optional page #

get '/user/:login/:page?' => sub {
    my $schema = schema('default');
    my $posts  = $schema->resultset('Post')->get_rendered(
        date_format    => config->{'date_format'},
        rows           => config->{'posts_per_page'},
        page           => param('page'),
        'poster.login' => param('login'),
    );
    ($posts) || status 404;

    ($posts) && (my $old_link = (scalar @{$posts} >= config->{'posts_per_page'}) ?
        "/user/" . param('login') . "/" .
            ((param('page') < 2) ? 2 : (param('page')) + 1) :
        undef);
    ($posts) && (my $new_link = (param('page') > 1) ?
        "/user/" . param('login') . "/" . (param('page') - 1) :
        undef);

    template 'index' => {
        title  => config->{'appname'},
        app    => config->{'appname'},
        byline => config->{'byline'},
        posts  => $posts || undef,
        user   => param('login'),
        older  => $old_link,
        newer  => $new_link,
    };
};

# RSS feed, can be limited to a single user.

get '/feed/:login?' => sub {
    my $schema = schema('default');

    content_type('application/rss+xml');    # or xml+rss?
    my $rss = XML::RSS->new( version => '2.0' );

    my $posts =
      $schema->resultset('Post')->get_rendered( login => param('login'), );
    $rss->channel(
        title       => config->{'appname'},
        description => config->{'byline'},
        link        => config->{'www_root'},
        pubDate     => $posts->[0]->{'rss_stamp'},
    );
    for my $post ( @{$posts} ) {
        $rss->add_item(
            title       => $post->{'subject'},
            permaLink   => config->{'www_root'} . "post/" . $post->{'id'} . '/',
            description => $post->{'text'},
        );
    }
    $rss->as_string;
};

# Get and verify comment postings, redirect with status message

post '/post/:post_id/:post_key?' => sub {
    my $schema = schema('default');

    my $post_id  = param('post_id');
    my $post_key = param('post_key');

    try {
        $schema->resultset('Comment')->create({
            post_id => $post_id,
            name => "" . param('name'),
            approved => (param('level1')) ? 0 : 1,
            date => time,
            email => "" . param('email'),
            website => "" . param('website'),
            two_cents => "" . param('two_cents')
        });
        forward "/post/$post_id/$post_key#comment", {
            comment_msg => "Thanks for posting! Your comment might take some time to appear.",
            comment_success => 1,
        },
        { method => 'get'};
    }
    catch {
        my ($msg) = (($_ =~ /WjournalValidate/) ?
            ($_ =~ /.*<(.*)>.*/) :
            "Sorry, there was a problem submitting your comment, please try again later.");

        return forward "/post/$post_id/$post_key#comment", {
            comment_msg => $msg,
            comment_success => 0,
        },
        { method => 'get'};
    }
};

1;

__END__

=encoding utf-8

=head1 NAME

Wjournal - The Welterweight (i.e. not quite Lightweight) blogging
system built on Perl5 and Dancer2.

=head1 SYNOPSIS

See L</DEPLOYMENT>

Site is currently deployed (as of July 2013) on http://www.fuzzix.org/

=head1 DESCRIPTION

Wjournal is yet another blog engine, to salve the author's NIH shakes.
It offers nothing new or radical.

It is designed for use on *nix services with any number of users. Post,
user and comment management are performed using a set of scripts
invoked from the shell. Posts themselves are plain files you can import
into the database using these scripts.

Posting access to the site is designed to be controlled by *nix group
permissions. That is, whoever has permission to run the posting scripts
and read the site's config has sufficient access to create and edit
posts.

The sole access restriction in the code itself is the presence of a
designated admin (or admins), provided access to all users' posts and
account details. Ordinarily users are only able to access elements
belonging to their own uid.

=head1 POST MANAGEMENT

Post creation, modification and deletion is handled by scripts/post.

By default, posts start out unpublished. Upon creation, a preview URL
is provided for the post, you can choose to publish then or do it
later.

scripts/post also Has delete/update/search and other control features
for posts.

Currently supported file types are Markdown (as interpreted by
L<Text::Markdown>), plain text (presented with HTML::Entities) and
HTML.

Default operation of scripts/post is to derive the subject line from
the file name (using config option 'space_char' to insert spaces) and
the filetype from its extension, so:

$ scripts/post This_is_a_new_post.md

...will create a new markdown post with subject "This is a new post",
provide a URL to preview the post and provide the option of publishing.
Unpublished posts essentially remain private, with access controlled by
their unique URL.

=head1 FILE MANAGEMENT

If uploads are allowed (controlled by permissions on the
public/uploads/ directory), scripts/upload can be used to make files
publicly available and generate thumnails for images.

Currently there are no access controls/limits file type, size and such
(See L</THE HONOUR SYSTEM>).

=head1 COMMENT MANAGEMENT

There is currently no comment management/queueing system implemented,
though there are plans to create one.

Current spam mitigation amounts to a trivial "Are you human?" check.

=for comment

B<NOTE : CSRF CURRENTLY NOT IMPLEMENTED>

A simple pair of mechanisms are used to mitigate potential spam, CSRF
Session validation and a trivial "human" check. The CSRF validation
does not report an HTTP error in order to not provide too many clues to
form bots, though a human should spot something is wrong.

It's still fairly trivial to automate comment submission
programatically, the intent of these measures is just to take ourselves
out of the set of very low hanging fruit.

=cut

=head1 USER MANAGEMENT

Anyone with access to the scripts, configuration and database may
post.

This can be managed by creating a group for posters, changing access
permissions for, at the very least, the configuration files and (in the
case of mysql) the database files. Ideally the post/user management
scripts would also be made accessible only to your designated users.

More information on how to achieve this is available in L</DEPLOYMENT>.

Users have the following properties:

 - uid:   Matches the system uid for that user, set on creation.
 - login: Matches the system login for that user, set on creation.
   This is used to link to user pages.
 - name:  A free form text field, the display name on posts.
   This is set from login by default, since the passwd info field is
   often empty.
 - admin: User is an administrator with access to the posts and
   details of other users.

'Admin' exists solely to prevent users accidentally stepping on each
others' toes by overwriting posts or user details. It is recommended
that the designated admin user is a non-posting user (e.g. your http
services user).

Add users to the posting group like so:

 # usermod -aG wjournal [username]

=head1 THE HONOUR SYSTEM

The security model of this software requires a little setup and may be,
for all I know, fundamentally flawed.

Before proceeding with the description of some deployment strategies,
it should be pointed out that you shouldn't give publishing rights to
users you do not trust.

What's to stop one of your designated users making themselves an admin,
editing everybody's posts and changing their name to "Rumpelstiltskin"?
Very little, hence the admonishment above. Admin is more a convenience
mechanism and less (i.e. not) a security mechanism.

With that in mind, on with the show...

=head1 DEPLOYMENT

Installation checklist :-

 - Install
 - Create group
 - Permissions
 - Configuration
 - Schema Installation

=head2 Install

Install:

Perl (v5.10.1 or later by my reckoning)
Dancer2
Dancer2::Plugin::DBIC
Data::UUID
File::Slurp
HTML::Entities
!Plack::Middleware::CSRFBlock
!Plack::Middleware::Session
Text::Markdown
URI::Escape

Recommended:

Starman

While site contents are not managed from the web frontend itself, the
Plack middlewares listed above are part of the anti-spam strategy for
comments.

Install this code to a location accessible to the user serving it.
Depending on how you choose to deploy this could be apache's user
(using mod_psgi) or an account created to run plackup instances.

My own preferred configuration tends towards the latter with reverse
proxying provided by nginx, so that's what this document will describe.

The rest of this section assumes you have installed the code to:

/home/wjournal/apps/Wjournal

...via git or some versioned release. Please adjust paths listed for
your own installation.

=head2 Create group

Membership of this group will control who gets to post to the site.
Select an unused GID and name for the group and, as root:

# groupadd -g 666 wjournal

=head2 Permissions

Much of this setup may be unnecassary on a system with only one user
(or only trusted users) so you are free to pick, choose and modify as
you require.

Note on sqlite : While deployment on sqlite is possible, special care
needs to be taken on file permissions since it relies no no daemon
gatekeeper or SQL GRANTs.

So, to set the appropriate permissions to allow only designated members
of the wjournal group to post:

 # find /home/wjournal/apps/Wjournal -type d -exec chmod 0750 {} +
 # find /home/wjournal/apps/Wjournal -type f -exec chmod 0640 {} +

If you want to serve static content directly from your server, you'll
need to give it access:

 # find /home/wjournal/apps/Wjournal/public -type d -exec chmod 0751 {} +
 # find /home/wjournal/apps/Wjournal/public -type f -exec chmod 0644 {} +

And if allowing hosting images/files with the upload script:

 # chmod 0771 /home/wjournal/apps/Wjournal/public/uploads

And finally, make scripts executable:

 # chmod 0750 /home/wjournal/apps/Wjournal/scripts/*

If using SQLite, you should set the database to be writable by the
whole group:

 # chmod 0660 /home/wjournal/apps/Wjournal/db/Wjournal.db

Then:

 # chown -R wjournal:wjournal /home/wjournal/apps/Wjournal

Where wjournal:wjournal are the hosting user:group you have configured.

I recommend creating a script setting up these permissions to ease
installation and upgrades.

Users can add /home/wjournal/apps/Wjournal/scripts to their path or
create links to the scripts they require to a directory in their path
which is under their control (e.g. ~/bin/).

=head2 Configuration

See config.yml.sample for an example config - if you wish to use SQLite
you could use this configuration as-is.

Database configuration is as described in L<Dancer2::Plugin::DBIC>
As with any Dancer(2) application, environment specific configs are
available in the conf/ directory.

=head2 Schema Installation

This project makes use of L<DBIx::Class::Schema::Versioned> to aid
installation and upgrade. A helper script has been supplied to roll out
the database schema.

Once your database has been configured, run:

 $ scripts/schema-install

...to create the schema. This supports Postgres, MySQL and SQLite. If
you wish to create tables on another relational store, DDL files can be
found in sql/.

=head1 TODO

 - Consolidate template construction.
 - Posting from GPG signed mail?
 - Posting from a git repository?
 - Comment moderation queue, auto-allow commenters (based on email?
   Cookie?).

=head1 SUPPORT

=head2 Bugs / Features / Comments / Suggestions

Please direct bug reports and feature requests to:

https://github.com/jbarrett/Wjournal/issues

=head2 Code / Updates

Updates will be made available on the github project page:

https://github.com/jbarrett/Wjournal/

Contributions welcome. See L</LICENSE>.

=head1 AUTHOR

John Barrett E<lt>john@jbrt.orgE<gt>

=head1 COPYRIGHT

Copyright 2013- John Barrett

=head1 LICENSE

This application is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut

