use strict;
use warnings;
package WebService::SendGrid::Newsletter::Schedule;

=method new

Creates a new instance of WebService::SendGrid::Newsletter::Schedule.

    my $schedule = WebService::SendGrid::Newsletter::Schedule->new(sgn => $sgn);

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
    
    $self->{sgn}->_send_request('schedule/add', %args);
}

sub get {
    my ($self, %args) = @_;
    
    $self->{sgn}->_send_request('schedule/get', %args);
}

sub delete {
    my ($self, %args) = @_;
    
    $self->{sgn}->_send_request('schedule/delete', %args);
}

1;
