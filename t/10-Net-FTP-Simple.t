#
# t/10-Net-FTP-Simple.t - Tests for Net::FTP::Simple
#
# Written by Wil Cooley
#
use strict;
use warnings;
use English         qw( -no_match_vars );
use Test::More      qw( no_plan );
use Net::FTP::Fake;

BEGIN {
    use_ok('Net::FTP::Simple');
}

{
    my $test = "Basic";

    # Croak if no 'server'
    eval {
        Net::FTP::Simple->_new({});
    };
    if ($EVAL_ERROR) { die $EVAL_ERROR; }

}
