package Net::FTP::Fake;
use strict;
use warnings;
use Carp;
use English         qw( -no_match_vars );

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
