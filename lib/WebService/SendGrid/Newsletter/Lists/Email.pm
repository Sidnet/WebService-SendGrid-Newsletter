use strict;
use warnings;
package WebService::SendGrid::Newsletter::Lists::Email;

use JSON;

=method new

Creates a new instance of WebService::SendGrid::Newsletter::Lists::Email.

    my $email = WebService::SendGrid::Newsletter::Lists::Email->new(
        sgn => $sgn
    );

Parameters:

=over 4

=item * sgn

An instance of WebService::SendGrid::Newsletter.

=back

=cut

sub new {
    my ($class, %args) = @_;
    
    my $self = {};
    bless($self, $class);
    
    $self->{sgn} = $args{sgn};
    
    return $self;    
}

sub add {
    my ($self, %args) = @_;
    
    if (ref $args{data} eq 'HASH') {
        # Data is a hashref -- turn it into JSON
        $args{data} = encode_json $args{data};
    }
    elsif (ref $args{data} eq 'ARRAY') {
        # Data is an arrayref of hashrefs -- turn each item into JSON
        $args{data} = [ map { encode_json $_; } @{$args{data}} ];
    }
    
    return $self->{sgn}->_send_request('lists/email/add', %args);
}

1;
