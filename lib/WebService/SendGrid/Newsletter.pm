use strict;
use warnings;
package WebService::SendGrid::Newsletter;

# ABSTRACT: Perl interface to SendGrid Newsletter API
# VERSION

use Carp;
use HTTP::Request::Common;
use JSON;
use LWP::UserAgent;

use WebService::SendGrid::Newsletter::Lists;
use WebService::SendGrid::Newsletter::Recipients;
use WebService::SendGrid::Newsletter::Schedule;

=head1 SYNOPSIS

    my $sgn = WebService::SendGrid::Newsletter->new(api_user => 'user',
                                                    api_key => 'SeCrEtKeY'
                                                    identity => 'johndoe');

    # Create a new recipients list
    $sgn->lists->add(list => 'subscribers', name => 'name');

    # Add a recipient to the list
    $sgn->lists->email->add(list => 'subscribers',
                            data => { name => 'Tom', email => 'tom@foo.com' });

    # Create a new newsletter
    $sgn->add(identity => 'johndoe',
              name => 'first newsletter',
              subject => 'Your weekly newsletter',
              text => 'Hello, this is your weekly newsletter',
              html => '<h1>Hello</h1><p>This is your weekly newsletter</p>');

    # Assign recipients list to the newsletter
    $sgn->recipients->add(name => 'first newsletter', list => 'subscribers');

    # Schedule the newsletter to be sent in 30 minutes
    $sgn->schedule->add(name => 'first newsletter', after => 30);

=method new

Creates a new instance of WebService::SendGrid::Newsletter.

    my $sgn = WebService::SendGrid::Newsletter->new(api_user => 'user',
                                                    api_key => 'SeCrEtKeY');

Parameters:

=over 4

=item * api_user

=item * api_key

=back

=cut

sub new {
    my ($class, %args) = @_;

    my $self = {};
    bless($self, $class);

    $self->_check_required_args([ qw( api_user api_key ) ], %args);

    $self->{api_user} = $args{api_user};
    $self->{api_key} = $args{api_key};
    
    $self->{ua} = LWP::UserAgent->new;
    $self->{ua}->agent(__PACKAGE__ . "/$VERSION (Perl)");

    $self->{last_response} = undef;
    $self->{last_response_code} = undef;
    
    if (exists $args{identity}) {
        $self->{identity} = $args{identity};
    }
    
    return $self;
}

# Sends a request to SendGrid Newsletter API
sub _send_request {
    my ($self, $path, %args) = @_;
    
    my $json = encode_json \%args;
    
    my $url = 'https://sendgrid.com/api/newsletter/' . $path . '.json';
    
    my $request = POST($url, { api_user => $self->{api_user}, 
        api_key => $self->{api_key}, %args });
    
    my $response = $self->{ua}->request($request);
    
    $self->{last_response_code} = $response->code;
    $self->{last_response} = decode_json $response->decoded_content;

    return !$response->is_error;
}

# Checks if the required arguments are present
sub _check_required_args {
    my ($self, $required_args, %args) = @_;

    foreach my $arg ( @{$required_args} ) {
        if (!exists $args{$arg}) {
            croak "Required parameter '$arg' is not defined";
        }
    }
}

=method get

Retrieves an existing newsletter.

Parameters:

=over 4

=item * name

B<(Required)> The name of the newsletter to retrieve.

=back

=cut

sub get {
    my ($self, %args) = @_;

    $self->_check_required_args([ qw( name ) ], %args);

    if ($self->_send_request('get', %args)) {
        return $self->{last_response};
    }
    else {
        return;
    }
}

=method add

Creates a new newsletter.

Parameters:

=over 4

=item * identity

B<(Required)> The identity that will be assigned to this newsletter. Can be
ommitted if it was given as an argument when the
WebService::SendGrid::Newsletter instance was created.

=item * name

B<(Required)> The name of the newsletter.

=item * subject

B<(Required)> The subject line of the newsletter.

=item * text

B<(Required)> The text contents of the newsletter.

=item * html

B<(Required)> The HTML contents of the newsletter.

=back

=cut

sub add {
    my ($self, %args) = @_;

    if (!exists $args{identity}) {
        $args{identity} = $self->{identity};
    }

    $self->_check_required_args([ qw( identity name subject text html ) ],
        %args);

    return $self->_send_request('add', %args);
}

=method edit

Modifies an existing newsletter.

Parameters:

=over 4

=item * identity

B<(Required)> The identity that will be assigned to this newsletter.

=item * name

B<(Required)> The existing name of the newsletter.

=item * newname

B<(Required)> The new name of the newsletter.

=item * subject

B<(Required)> The subject line of the newsletter.

=item * text

B<(Required)> The text contents of the newsletter.

=item * html

B<(Required)> The HTML contents of the newsletter.

=back

=cut

sub edit {
    my ($self, %args) = @_;

    $self->_check_required_args([ qw( name newname identity subject text
        html ) ], %args);

    return $self->_send_request('edit', %args);
}

=method list

Retrieves a list of all newsletters.

Parameters:

=over 4

=item * name

Newsletter name. If provided, the call checks if the specified newsletter
exists.

=back

=cut

sub list {
    my ($self, %args) = @_;

    if ($self->_send_request('list', %args)) {
        return $self->{last_response};
    }
    else {
        return;
    }
}

=method delete

Deletes a newsletter.

Parameters:

=over 4

=item * name

B<(Required)> The name of the newsletter to delete.

=back

=cut

sub delete {
    my ($self, %args) = @_;

    $self->_check_required_args([ qw( name ) ], %args);

    return $self->_send_request('delete', %args);
}

=method lists

Returns an instance of L<WebService::SendGrid::Newsletter::Lists>, which is used
to manage recipient lists.

=cut

sub lists {
    my ($self) = @_;

    if (!defined $self->{lists}) {
        $self->{lists} = WebService::SendGrid::Newsletter::Lists->new(
            sgn => $self
        );
    }

    return $self->{lists};
}

=method recipients

Returns an instance of L<WebService::SendGrid::Newsletter::Recipients>, which
allows to assign recipient lists to newsletters.

=cut

sub recipients {
    my ($self) = @_;

    if (!defined $self->{recipients}) {
        $self->{recipients} =
            WebService::SendGrid::Newsletter::Recipients->new(sgn => $self);
    }

    return $self->{recipients};
}

=method schedule

Returns an instance of L<WebService::SendGrid::Newsletter::Schedule>, which is
used to schedule a delivery time for a newsletter.

=cut

sub schedule {
    my ($self) = @_;

    if (!defined $self->{schedule}) {
        $self->{schedule} =
            WebService::SendGrid::Newsletter::Schedule->new(sgn => $self);
    }

    return $self->{schedule};
}

=method last_response_code

Returns the code of the last response from the API.

=cut

sub last_response_code {
    my ($self) = @_;

    return $self->{last_response_code};
}

=method last_response

Returns the data structure retrieved with the last response from the API.

=cut

sub last_response {
    my ($self) = @_;

    return $self->{last_response};
}

1;

