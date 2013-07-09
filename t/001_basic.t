use strict;
use warnings;

# Test pre-requisites / dependencies / basic routes

use Test::More tests => 3;

BEGIN { use_ok 'Wjournal' };
BEGIN { use_ok 'Dancer2::Test' };

set environment => 'testing';

response_status_is ['GET' => '/'], 200, 'response status is 200 for /';

