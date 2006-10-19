#
# t/10-Net-FTP-Simple.t - Tests for Net::FTP::Simple
#
# Written by Wil Cooley
#
use lib             qw( tlib );
use strict;
use warnings;
use English         qw( -no_match_vars );
use Test::More      qw( no_plan );
use Test::MockObject;
#use Net::FTP::Fake;

BEGIN {
    use_ok('Net::FTP::Simple');
}

{
    my $test = "Basic";

    # Croak if no 'server'
    eval {
        Net::FTP::Simple->_new({});
    };
    if ($EVAL_ERROR =~ m/requires at least 'server' parameter/) { 
        pass("$test: Correctly fail on missing parameters");
    }
    else {
        fail("$test: Did not fail with missing parameters");
    }

    ok(my $fake_conn = new_mock_ftp(), "$test: New Net::FTP mock object");

    ok(my $ftp_simple = Net::FTP::Simple->_new({
            conn    => $fake_conn,
            server  => 'localhost',
    }), "$test: New object with fake connection");

}

{
    my $test = "list_files";

    my @input_file_list = (
        'drwxr-xr-x    2 2171     2172         4096 Sep 29 17:35 dir with spaces',
        'prw-r--r--    1 0        0               0 Sep 29 17:37 fifo-test',
        '-rw-r--r--    1 2171     2172        55082 Sep 29 20:42 merccurl-auth-page.html',
        'drwxr-xr-x    2 0        0            4096 Sep 29 16:46 testdir',
        '-rwxr-xr-x    1 0        0            6660 Oct 16 18:08 foo',
    );

    my @expected_list = (
        'merccurl-auth-page.html',
        'foo',
    );

    ok(my $fake_conn = new_mock_ftp(), "$test: New Net::FTP mock object");

    $fake_conn->set_list('dir', @input_file_list);

    ok(my @files = Net::FTP::Simple->list_files({
            conn    => $fake_conn,
            server  => 'localhost',
    }), "$test: Returns something true");

    is_deeply(\@files, \@expected_list, "$test: Returned list correct");

}

# Do some basic setup of the mock object
sub new_mock_ftp {
    my $fake_conn = Test::MockObject->new();

    $fake_conn->set_true( qw( login binary ok quit ) );

    return $fake_conn;
}
