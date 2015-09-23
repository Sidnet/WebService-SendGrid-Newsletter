#!/usr/bin/env perl

package WebService::SendGrid::Newsletter::Test::Schedule;

use strict;
use warnings;

use lib 't/lib';

use DateTime;
use Test::More;
use Test::Exception;

use WebService::SendGrid::Newsletter;

use parent 'WebService::SendGrid::Newsletter::Test::Base';

my $list_name       = 'subscribers_test';
my $newsletter_name = 'Test Newsletter';

sub startup : Test(startup => no_plan) {
    my ($self) = @_;

    $self->SKIP_ALL('SENDGRID_API_USER and SENDGRID_API_KEY are ' .
        'required to run live tests')
        unless $ENV{SENDGRID_API_USER} && $ENV{SENDGRID_API_KEY};

    # Create a new recipients list
    $self->sgn->lists->add(list => $list_name, name => 'name');

    $self->sgn->lists->email->add(
        list => $list_name,
        data => { name  => 'Some One', email => 'someone@example.com' }
    );

    my %newsletter = (
        name     => $newsletter_name,
        identity => 'This is my test marketing email',
        subject  => 'Your weekly newsletter',
        text     => 'Hello, this is your weekly newsletter',
        html     => '<h1>Hello</h1><p>This is your weekly newsletter</p>'
    );
    $self->sgn->add(%newsletter);

    # Give SendGrid some time for the changes to become effective
    sleep(60);

    $self->sgn->recipients->add(name => $newsletter_name, list => $list_name);
}

sub shutdown : Test(shutdown) {
    my ($self) = @_;

    $self->sgn->lists->delete(list => $list_name);
    $self->sgn->delete(name => $newsletter_name);
}

sub schedule : Tests {
    my ($self) = @_;

    throws_ok
        {
            $self->sgn->schedule->add->(list => $list_name);
        }
        qr/Required parameter 'name' is not defined/,
        'An exception is thrown when a required parameter is missing';

    my $dt = DateTime->now();
    $dt->add(minutes => 2);

    $self->sgn->schedule->add(name => $newsletter_name, at => "$dt");
    $self->expect_success($self->sgn, 'Scheduling a specific delivery time');

    $self->sgn->schedule->add(name => $newsletter_name, after => 5);
    $self->expect_success($self->sgn, 'Scheduling delivery in a number of minutes');

    throws_ok
        {
            $self->sgn->schedule->add->();
        }
        qr/Required parameter 'name' is not defined/, 
        'An exception is thrown when a required parameter is missing';

    $self->sgn->schedule->get(name => $newsletter_name);
    ok($self->sgn->{last_response}->{date},
        'Date is set when retrieving a scheduled delivery');

    throws_ok
        {
            $self->sgn->schedule->delete->();
        }
        qr/Required parameter 'name' is not defined/, 
        'An exception is thrown when a required parameter is missing';


    $self->sgn->schedule->delete(name => $newsletter_name);
    $self->expect_success($self->sgn, 'Deleting a scheduled delivery');
}

Test::Class->runtests;
