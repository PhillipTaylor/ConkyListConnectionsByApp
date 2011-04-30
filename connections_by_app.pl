#!/usr/bin/env perl

use strict;
use warnings;

sub clean_process_name {
	my $dirty_name = shift;

	if ($dirty_name =~ /firefox-bin/) {
		return "iceweasel";
	}
	
	if ($dirty_name =~ /telepathy-gabble/) {
		return "empathy";
	}

	if ($dirty_name =~ /python (.*)/) {
		$dirty_name = $1;
	}
	
	if ($dirty_name =~ /.*\/(.*)$/) {
		$dirty_name = $1;
	}

	return $dirty_name;
}

# STEP 1. READ IN THE OUTPUT OF PS.
#----------------------------------

open my $fh, "ps aux |"
	or die "cant run ps";

my %progs = (); # keyed on pid

foreach my $line (<$fh>) {
	if ($line =~ /^(\S+)\s+(\d+).{51}(.*)/) {

		my $user     = $1;
		my $pid      = $2;
		my $app_name = clean_process_name($3);

		$progs{$pid} = {
			"user"     => $user,
			"pid"      => $pid,
			"app_name" => $app_name
		};
	}
}

close $fh;

# STEP 1. READ IN THE OUTPUT OF NETSTAT
#----------------------------------
open $fh, "netstat -an --program 2>/dev/null |"
	or die "cant access netstat";

my %pids = ();

foreach my $line (<$fh>) {

	if ($line =~ /^(tcp|udp).*:(\d+).* (\S+)\//) {

		my $proto = $1;
		my $port = $2;
		my $pid = $3;

		#print "proto: $proto, port: $port, pid: $pid\n";

		if (defined $pids{$pid}) {
			$pids{$pid}{"count"} += 1;
		} else {

			my $app_name = 'Unknown';
			my $user = '';

			if (defined $progs{$pid}) {
				$app_name = $progs{$pid}{"app_name"};
				$user = $progs{$pid}{"user"};
			}

			$pids{$pid} = {
				"proto"    => $proto,
				"port"     => $port,
				"pid"      => $pid,
				"app_name" => $app_name,
				"user"     => $user,
				"count"    => 1
			};
		}
	}
}

# PRINT OUT THE RESULTS!
#-----------------------

my $v = '';

foreach my $pid (keys %pids) {

	$v = $pids{$pid};

	# outputs data in the format app_name (user@tcp:8080) x 61)
	print "$v->{'app_name'} "
		. "($v->{'user'}\@$v->{'proto'}:$v->{'port'})"
		. " x $v->{'count'}\n";

}

close $fh;

