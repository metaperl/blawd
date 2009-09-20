package Blawd::View::API;
use Moose::Role;
use namespace::autoclean;

requires qw(render_entry);

sub render {
    my ( $self, @entries ) = @_;
    $self->render_entry($_) for @entries;
}

1;
__END__
