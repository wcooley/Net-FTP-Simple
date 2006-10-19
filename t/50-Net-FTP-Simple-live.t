#!/usr/bin/perl
#
use strict;
use warnings;
use Data::Dumper;
use English         qw( -no_match_vars );
use Test::More;

BEGIN {
    use_ok('Net::FTP::Simple');
}

unless (exists $ENV{'NET_FTP_SIMPLE_LOGIN'}) {
    plan skip_all => 'FTP conn info missing; set env var'
                   . ' NET_FTP_SIMPLE_LOGIN="user:pass:server"';
}
else {
    plan tests => 5;
}

my %conn_info = parse_login_env();

{
    my $test = "list_files";
    my @expected = (qw(test-file));
    my @remote_files;

    my $test_conn = {
        %conn_info,
        remote_dir  => 'whehere',
    };

    ########################################
    # Test w/o filter
    ########################################
    delete $test_conn->{'file_filter'};

    ok(@remote_files = Net::FTP::Simple->list_files($test_conn), 
        "$test: Returned something positive"
    );

    is_deeply(\@remote_files, \@expected, 
              "$test: Returned expected items w/o filter");

    ########################################
    # Test w/filter
    ########################################
    $test_conn->{'file_filter'} = qr/test/;

    ok(@remote_files = Net::FTP::Simple->list_files($test_conn), 
        "$test: Returned something positive"
    );

    is_deeply(\@remote_files, \@expected, 
              "$test: Returned expected items w/filter");


    ########################################
    # Test w/non-matching filter
    ########################################
    $test_conn->{'file_filter'} = qr/testBOGUS/;

    is(@remote_files = Net::FTP::Simple->list_files($test_conn), 0,
        "$test: Returned something positive");

}

sub parse_login_env {
    my %conn_info;

    @conn_info{ qw( username password server ) }
        = split(/:/, $ENV{'NET_FTP_SIMPLE_LOGIN'}, 3);

    return %conn_info;
} 
