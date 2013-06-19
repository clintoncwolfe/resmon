package Resmon::ExtComm;

use strict;
use warnings;

use base "Exporter";
our @EXPORT_OK = qw/cache_command run_command/;

my %commhist;
my %commcache;
my %children;

sub cache_command {
    my $expiry = pop;
    my @command = @_;
    my $command = join(" ", @command);

    my $now = time;
    if(defined $commhist{$command}  && $commhist{$command} > $now) {
        return $commcache{$command};
    }
    $commcache{$command} = run_command(@command);
    $commhist{$command} = $now + $expiry;
    return $commcache{$command};
}

sub clean_up {
    # Kill off any child processes started by run_command and close any pipes
    # to them. This is called when a check times out and we may have processes
    # left over.
    while (my ($pid, $handle) = each %children) {
        kill 9, $pid;
        close ($handle);
        delete $children{$pid};
    }
}

sub run_command {
    # Run a command just like `cmd`, but store the pid and stdout handles so
    # they can be cleaned up later. For use with alarm().
    my @cmd = @_;
    my $pid = open(my $r, "-|", @cmd);
    die "Can't run $cmd[0]: $!\n" unless defined($pid);
    $children{$pid} = $r;
    my @lines = <$r>;
    delete $children{$pid};
    close($r);
    return join("", @lines);
}

1;
