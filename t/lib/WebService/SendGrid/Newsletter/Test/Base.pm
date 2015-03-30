#!/usr/bin/env perl

package WebService::SendGrid::Newsletter::Test::Base;

use strict;
use warnings;

use Test::More;
use parent 'Test::Class';


sub expect_success {
    my ($self, $sgn, $test_name) = @_;

    is($sgn->{last_response}->{message}, 'success',
        $test_name . ' results in a successful response');
    is($sgn->{last_response_code}, 200,
        $test_name . ' results in a successful response code');
}

1;