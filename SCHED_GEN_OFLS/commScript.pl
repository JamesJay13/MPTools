#!/usr/bin/perl

#####################################################################
# commScript.pl
#
# Created by: Kevin Marsh
# Date Created: 09/23/99
#
# Version 1.1
#
# Change Log:
#
# Date     Modifier     Description
# ----     --------     -----------
# 09/24/99 K. Marsh     Added History function to keep tracked of last
#                       used pass number.
# 10/12/99 K. Marsh     Fixed bug dealing with SOA times in day previous
#                       to BOT.
# 01/05/99 K. Marsh     Fixed output of day numbers with less than 3 digits.
# 10/04/00 K. Marsh     Added fix for problem caused by lack of pass # with
#                       a work code of other than 1A1.
# 03/14/05 K. Marsh     Corrected parsing of data lines
# 11/30/05 K. Marsh     Removed use of PBK entries for Linus OFLS 11.5.2
# 12/23/08 D. Mabius    Fixed bug processing year in header line, and added
#  					comments throughout the script
# 12/23/08 D. Mabius    Added check to throw warning in case of missing SOE
#
#####################################################################

require "getopts.pl";
&Getopts('d:p:');


# Look for option '-d' containing DSN file from command line during execution,
#	else ask user for filename
if ($opt_d) {
    $dsnfile = $opt_d;
} else {
    print STDERR "Enter DSN schedule filename for processing. (i.e. DSN291_297.txt)\n";
    $dsnfile = <>;
}
chomp $dsnfile;

# Grab filename, exclude extension
($dsnfile) = ($dsnfile =~ /(.*)\.\S{3}/);

# Open DSN Schedule text file
open(DSN, "<$dsnfile.txt") || die "Cannot find DSN schedule file.";

# If filename ends in a non-digit character, grab as and use as version,
#	otherwise assign version as 'A'
if ($dsnfile =~ /\D$/) {

    $dsnfile =~ /.*\d(\D)$/;
    $ver_letter = $1;
    ($dsnfile) = ($dsnfile =~/(.*\d)\D/);
} else {
	
	$ver_letter = "A";
}


# Create ER file using DSN filename and '.er' extension
open(ER, ">$dsnfile.er") || die "Cannot create ER file.";
print ER "HDR, HDR_ID=$dsnfile\n\n";


# Create new DSN file using '.mp[version]' as extension
open(NEW, ">$dsnfile.mp$ver_letter") || die "Cannot create new DSN file.";


# Initialize starting pass number as 0
$pass_start = 0;

# If option '-p' assigned in command line, use it, otherwise open Comm history
#	file and look for last pass number
if ($opt_p) {

    $pass = $opt_p;
} else {

    # Grab last used pass number from temp file (comm.hst) [open for reading]
    open(HIST, "<comm.hst") || die "Cannot open Comm history file.";
    while (<HIST>){
		$line=$_;
		if ($line =~ /\#/) {
    		# Do nothing
		} else {
    		($pass_start) = ($line =~ /(\d*)/);
		}
    }
}

# Cycle through DSN file
while (<DSN>) {

	# Grab line, chomp off end-of-line return if present
	$line = $_;
    chomp $line;

	# Look for line in heading containing year
    if ($line =~ /WEEK/) {

		# Grab year associated with end time
		($year) = $line =~ /.*(\d{2}).*$/;
		if ($year >= 90) {
			$year = $year + 1900;
		} else {
	    	$year = $year + 2000;
		}		

		# Old code
		#($year) = ($line =~ /.*\d\d.*(\d\d).*/);
		#if ($year =~ /9/) {
		#	$year = $year + 1900;
		#} else {
	    #	$year = $year + 2000;
		#}
    }
    
	# Process lines containing ' CHDR ', otherwise look for lines beginning
	# with '*' and copy those lines directly to DSN Schedule file (.mp*)
    if ($line =~ /\sCHDR\s/) { # Match lines with pass info

		# Parse line into individual elements
		$line =~ /^(.{24})\s\s(.{6})\s\s(\w{4})\s\s\s(.{16})\s(.{4})\s\s(.{4})\s\s(.{5})/;
		$times = $1; $station = $2; $user = $3; $activity = $4; $oldpass = $5; $config = $6; $soe = $7;

		# Adjust variable assignment in the case of a missing pass no.
		if ($config =~ /1A1/ || $config =~ /3C1/) {
	    	$soe = $config;
	    	$config = $oldpass;
		}
	
		# Check for missing SOE
		if ($soe =~ /^\s*$/) {
			print "\nERROR: Possible missing SOE on following line:\n\t$_\n";
		}

		# Split time into components
		($day, $start, $bot, $eot, $end) = split(' ', $times);
	
		# Save day as it originally appears to be written in DSN Schedule file
		$dsnday = $day;
		($shour, $smin) = ($bot =~ /(\d\d)(\d\d)/);
		($ehour, $emin) = ($eot =~ /(\d\d)(\d\d)/);
	
		# Update day based on BOT.
		# 	If start time is greater than BOT, update day
		if ($start gt $bot)	{
	    	$day++;
		}

		# Determine end day -- if start time < end time add one to end day
		$eday = $day;
		if ($ehour lt $shour) {
	    	$eday = $day+1;
		}
		elsif ($ehour eq $shour) {
	    	if ($emin lt $smin) {
					$eday = $day + 1;
	    	}
		}
	
		# Grab station number
		($junk, $sta_num) = split('-', $station);
	
		# Determine pass number
		# Ideally if $pass_start == 0, then $pass was set by cmd line option '-p'
		# However it is also possible that no option was used at the command
		# 	line, the temporary file (comm.hst) was found, but was not formatted
		# 	correctly and $pass_start was never updated, in this case $pass
		#	is not set at this point.
		if ($pass_start eq 0) {
	    	$pass_start = $pass;
	    	if ($pass < 10) {
					($last2) = ($pass =~ /.*(.)/);
	    	}
	    	else {
					($last2) = ($pass =~ /.*(..)/);
	    	}
		}
		else {
	    	$pass = ++$pass_start;
	    	if ($pass < 10) {
					($last2) = ($pass =~ /.*(.)/);
	    	}
	    	else {
					($last2) = ($pass =~ /.*(..)/);
	    	}
		}
    
		# Output to ER Comm Request file.
		print ER "COMM,\n";
		printf ER "  ID=D%s%02d,\n", $sta_num, $last2;
		print ER "  PRIORITY=1,\n";
		print ER "  LINK=TRACKING,\n";
		print ER "  DURATION=(18800.0, 1800.0, 36000.0),\n";
		printf ER "  WINDOW=(%4d:%03d:%02d:%02d:00.000, %4d:%03d:%02d:%02d:00.000)\n\n", 
			$year, $day, $shour, $smin, $year, $eday, $ehour, $emin;

		# Output to DSN Schedule file.
		printf NEW " %03d %04d %04d %04d %04d  %s  %s   %-16s %04d  %4s  %s %3s\n",
			$dsnday, $start, $bot, $eot, $end, $station, $user, $activity, $pass, $config, 
			$soe, $work;
	}
	else {

		# If line begins with asterisk, print directly to DSN Schedule file.
		print NEW $_ if ($_ =~ /^\*/);
	}
}

# Close all open files
close(all);

# Reopen temp file for writing, rewrite temp file
open(HIST,">comm.hst") || die "Cannot open Comm history file.";
print HIST "# Last used Pass Number\n";
print HIST "$pass\n";

# Close temp file
close(HIST);
