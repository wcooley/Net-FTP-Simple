#!perl -T
#
# t/10-Net-FTP-Simple.t - Tests for Net::FTP::Simple
#
# Written by Wil Cooley
#
use lib             qw( tlib );
use strict;
use warnings;
use English         qw( -no_match_vars );
use Test::More      tests => 37;
use Test::MockObject;
#use Net::FTP::Fake;

BEGIN {
    use_ok('Net::FTP::Simple');
}

my @files_to_send 
    = map { 
        File::Spec->join('test-data', 'test-subdir', $_)
    } qw( file-a file-b file-c );

#######################################################################
# basic setup
#######################################################################
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

#######################################################################
# list_files
#######################################################################
{
    my $test = "list_files (basic)";
    ok(my $fake_conn = new_mock_ftp(), "$test: New Net::FTP mock object");
    my @files;

    my @input_file_list = (
        'drwxr-xr-x  2 2171 2172  4096 Sep 29 17:35 dir with spaces',
        'prw-r--r--  1 0    0        0 Sep 29 17:37 fifo-test',
        '-rw-r--r--  1 2171 2172 55082 Sep 29 20:42 merccurl-auth-page.html',
        'drwxr-xr-x  2 0    0     4096 Sep 29 16:46 testdir',
        '-rwxr-xr-x  1 0    0     6660 Oct 16 18:08 foo',
    );

    my @expected_list = (
        'merccurl-auth-page.html',
        'foo',
    );


    $fake_conn->set_list('dir', @input_file_list);

    ok(@files = Net::FTP::Simple->list_files({
            conn    => $fake_conn,
            server  => 'localhost',
    }), "$test: Returns something true");

    is_deeply(\@files, \@expected_list, "$test: Returned list correct");


    # Add a filter
    ok(@files = Net::FTP::Simple->list_files({
            conn        => $fake_conn,
            server      => 'localhost',
            file_filter => qr/merccurl/,
    }), "$test: Returns something true");

    is_deeply(\@files, [ $expected_list[0] ], 
              "$test: Returned list w/filter correct");

}

#######################################################################
# list_files
#   -> empty list
#######################################################################
{
    my $test = "list_files (empty list)";
    ok(my $fake_conn = new_mock_ftp(), "$test: New Net::FTP mock object");

    $fake_conn->set_list('dir', ());

    my @files = Net::FTP::Simple->list_files({
            conn    => $fake_conn,
            server  => 'localhost',
    });

    is_deeply(\@files, [], "$test: Returns empty list");
}

#######################################################################
# send_files
#######################################################################
{
    my $test = "send_files (basic)";

    my @succ_transfers;

    ok(my $fake_conn = new_mock_ftp(), "$test: Net::FTP mock object");

    $fake_conn->set_true( qw( put rename message ) );

    ok(@succ_transfers = Net::FTP::Simple->send_files({
            conn    => $fake_conn,
            server  => 'localhost',
            files   => \@files_to_send,
    }), "$test: Returns non-empty list");

    is_deeply(\@succ_transfers, \@files_to_send, "$test: Sends all files");
}


#######################################################################
# send_files
#   -> test 'retry'
#######################################################################
{
    my $test = "send_files (retry)";

    # Don't really want it to wait the whole retry period
    $Net::FTP::Simple::retry_wait{'rename'} = 0;

    my ($retries, $pattern, $sub, @succ_transfers);

    my $warn_handlers = {
        qr/Error renaming '(file-.\.tmp)' to '(file-.)'/ms          
            => sub {
                my ($from, $to) = @_;
                pass("$test: Correctly failed to rename '$from' to '$to'");
            },
        };

    setup_warning_handler($test, $warn_handlers);

    ok(my $fake_conn = new_mock_ftp(), "$test: Net FT::FTP mock object");

    $fake_conn->set_true( qw( put ) );
    $fake_conn->set_always(
        'message' =>      qq/The process cannot access the file because /
                        . qq/it is being used by another process/
    );

    # The first try of the first two files will fail, 
    # The third file will succeed on the first try
    $fake_conn->set_series('rename', 0, 1, 0, 1, 1);
   ($pattern, $sub)  = _gen_sub_count_transfer_tries($test, 
        $files_to_send[0] => 2,
        $files_to_send[1] => 2,
        $files_to_send[2] => 0,
   );

   $warn_handlers->{ $pattern } = $sub;         


    ok(@succ_transfers = Net::FTP::Simple->send_files({
            conn    => $fake_conn,
            server  => 'localhost',
            files   => \@files_to_send,
    }), "$test: Returns non-empty list");

    is(@succ_transfers, 3, "$test: 3 files sent");

    #
    # Fail once on the first file
    # Twice on the second file
    # Four times (which is the max) on the third
    #   There is a final one to catch the potential case where the third does
    #   not fail after four tries.
    #
    # Note that there is a potential off-by-one here: The $retry_max{'rename'}
    # is 3, which means there should be I<4> tries (which is one try and 
    # I<3> retries!).
    #
    $fake_conn->set_series('rename', 0, 1, 0, 0, 1, 0, 0, 0, 0, 1);
    ($pattern, $sub) =  _gen_sub_count_transfer_tries($test, 
        $files_to_send[0]   => 2,
        $files_to_send[1]   => 3,
        $files_to_send[2]   => 0,
    );

    $warn_handlers->{ $pattern } = $sub;

    ok(@succ_transfers = Net::FTP::Simple->send_files({
            conn    => $fake_conn,
            server  => 'localhost',
            files   => \@files_to_send,
    }), "$test: Returns non-empty list");

    is(@succ_transfers, 2, "$test: 2 files set, one failed");

    #-----------------------------------------------------

    #
    # Fail the max number of tries to ensure that failure will happen
    #

    $retries = $Net::FTP::Simple::retry_max{'rename'};

    $fake_conn->set_series('rename', map { 0 } 0..$retries );

    @succ_transfers = Net::FTP::Simple->send_files({
            conn    => $fake_conn,
            server  => 'localhost',
            files   => [ $files_to_send[0] ],
        });

    is_deeply(\@succ_transfers, [],
        "$test: 0 successes after max $retries retry failures");

}

# Do some basic setup of the mock object
sub new_mock_ftp {
    my $fake_conn = Test::MockObject->new();

    $fake_conn->set_true( qw( login binary ok quit ) );

    return $fake_conn;
}

#
# Setup $SIG{__WARN__} with a hash of I<pattern> => I<action> items.
# I<pattern> should be a regexp.  I<action> may be either something true or
# false or a code ref.  If a code ref, the code ref is called with any matches
# from the pattern comparison.
#
# Does not re-throw the warnings as might be desirable in non-test code.
#
sub setup_warning_handler {
    # Clear handler
    unless (@_) {
        delete $SIG{__WARN__};
        return;
    }

    my ($test, $expected_warnings) = @_;

    $SIG{__WARN__} = sub {
        my ($err) = @_;
        chomp $err;

        for my $warning (keys %{ $expected_warnings }) {
            if (my @matches = $err =~ m{ $warning }xms) {
                if ( ref $expected_warnings->{ $warning } eq 'CODE' ) {
                    $expected_warnings->{ $warning }->(@matches);
                }
                elsif ( $expected_warnings->{ $warning } ) {
                    pass("$test: Expected warning '$err'");
                }
                else {
                    fail("$test: Expected but failing warning '$err'");
                }
                return;
            }
        }
        fail("$test: Unexpected warning '$err'");
    };
}

# Yay for closures!
#
# _gen_sub_count_transfer_tries - This generates a code ref/anonymous
# subroutine which is a (key, value) pair for use w/setup_warning_handler.
# The $pattern matches the warning message from Net::FTP::Simple after a number
# of tries.  It expects a hash containing filenames and the expected number
# of tries.
#
sub _gen_sub_count_transfer_tries {
    my ($test, %expected_tries) = @_;
    my $pattern = qr/Transfer of file '(.*)' succeeded after (\d+) tries/ms;

    return $pattern => sub {
            my ($filename, $tries) = @_;
            
            unless (exists $expected_tries{ $filename }) {
                fail("$test: Did not expect failure of file '$filename'");
                return;
            }

            is($tries, $expected_tries{ $filename },
                "$test: Successfully sent '$filename' after $tries tries");
        };
}
