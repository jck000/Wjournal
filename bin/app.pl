#!/usr/bin/env perl

use strict;
use warnings;

#use Plack::Builder;
#use Dancer2::Request;
use Dancer2;
use Wjournal;

#my $app = sub {
#    use DDP; p @_;
#    Dancer2->dance(Dancer2::Request->new(@_));
#};
#
#
#builder {
#  enable 'Session';
#  enable 'CSRFBlock',
#    parameter_name => 'csrf_secret',
#    token_length => 20,
#    session_key => 'csrf_token',
#    blocked => sub {
#      [302, [Location => 'http://www.google.com'], ['']];
#    },
#    onetime => 0,
#    ;
#    $app;
#    Dancer2->dance(Dancer2::Request->new(@_));
#};

dance;

