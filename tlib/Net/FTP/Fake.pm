#
# Net::FTP::Fake - Fake Net::FTP object useful for testing client code.
#
# Written by Wil Cooley <wcooley@nakedape.cc>
#
# $Id$
#
package Net::FTP::Fake;
use strict;
use warnings;
use Carp;
use English         qw( -no_match_vars );

our $VERSION = '0.0.1';

sub new {
    my ($class) = @_;
    my $obj = bless {}, $class;
    return $obj;
}

sub ascii {
}

sub binary {
}

sub code {
}

sub cwd {
}

sub delete {
}

sub dir {
}

sub get {
}

sub login {
    my ($self, $user, $pass) = @_;
    return 1;
}

sub message {
}

sub mkdir {
}

sub ok {
}

sub put {
}

sub rename {
}

1;

__END__

=head1 NAME

Net::FTP::Fake - Fake Net::FTP class; useful for testing.

=head1 VERSION

This document describes Net::FTP::Fake version 0.0.1.

=head1 INTERFACE

=over 4

=item new

=item ascii

=item binary

=item code

=item cwd

=item delete

=item dir

=item get

=item login

=item message

=item mkdir

=item ok

=item put

=item rename

=back
