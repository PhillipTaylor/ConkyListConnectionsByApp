#!/usr/bin/env perl

# Written by Phillip Taylor 2011

use strict;
use warnings;

# modify this function to control the output format.
sub print_line {
	my $v = shift;

	#available fields
	my $app_name = $v->{'app_name'};
	my $user     = $v->{'user'};
	my $proto    = $v->{'proto'};
	my $port     = $v->{'port'};
	my $count    = $v->{'count'};

	# e.g. irssi (phill@tcp:6667) x 1
	print "$app_name ($user\@$proto:$port) x $count\n";

}

# edit this function to clean up the names
# of processes if you want to.
sub clean_process_name {
	my $dirty_name = shift;

	if ($dirty_name =~ /firefox-bin/) {
		return "iceweasel";
	}
	
	if ($dirty_name =~ /telepathy-gabble/) {
		return "empathy";
	}

	# don't just show 'python' as the program name, use argument 1
	if ($dirty_name =~ /python (.*)/) {
		$dirty_name = $1;
	}

	# reduce /usr/bin/<app_name> to just <app_name>
	if ($dirty_name =~ /.*\/(.*)$/) {
		$dirty_name = $1;
	}

	return $dirty_name;
}

# READ IN THE OUTPUT OF PS.
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

# READ IN THE OUTPUT OF NETSTAT
#------------------------------

open $fh, "netstat -an --program 2>/dev/null |"
	or die "cant access netstat";

my %conns = (); # also keyed on pid

foreach my $line (<$fh>) {

	if ($line =~ /^(tcp|udp).*:(\d+).* (\S+)\//) {

		my $proto = $1;
		my $port = $2;
		my $pid = $3;

		#print "proto: $proto, port: $port, pid: $pid\n";

		if (defined $conns{$pid}) {
			$conns{$pid}{"count"} += 1;
		} else {

			my $app_name = 'Unknown';
			my $user = '';

			if (defined $progs{$pid}) {
				$app_name = $progs{$pid}{"app_name"};
				$user = $progs{$pid}{"user"};
			}

			$conns{$pid} = {
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

foreach my $pid (keys %conns) {
	print_line($conns{$pid});
}

close $fh;

