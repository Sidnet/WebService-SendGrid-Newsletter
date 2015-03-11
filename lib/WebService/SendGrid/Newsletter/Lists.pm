use strict;
use warnings;
package WebService::SendGrid::Newsletter::Lists;

use WebService::SendGrid::Newsletter::Lists::Email;

=method new

Creates a new instance of WebService::SendGrid::Newsletter::Lists.

    my $lists = WebService::SendGrid::Newsletter::Lists->new(sgn => $sgn);

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

    return $self->{sgn}->_send_request('lists/add', %args);
}

sub get {
    my ($self, %args) = @_;

    return $self->{sgn}->_send_request('lists/get', %args);
}

sub email {
    my ($self) = @_;
    
    if (!defined $self->{email}) {
        $self->{email} = WebService::SendGrid::Newsletter::Lists::Email->new(
            sgn => $self->{sgn}
        );
    }
    
    return $self->{email};
}

1;
