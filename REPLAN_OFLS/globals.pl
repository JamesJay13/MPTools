#!/usr/bin/perl
use Data::Dumper;
#########################################################################
# globals.pl
#
# This script is designed to automate the process of creating the Globals.fot
# file in the event that command load generation needs to be run in a 
# non-continuity state.
#
# Change Log
# ----------
# 03/22/02   K. Marsh   Corrected SCS107 setting of HRC_DOOR_OPEN to 'FALSE'
# 07/18/12   S. Mancini Redesigned for SOSA
#
#########################################################################

@Glob_keys = qw(G_ACQFLG G_MANFLG G_SUNPOSMON G_TLM_FMT G_IU_ID PREV_HRC_DETECTOR PREV_HRC_DEF_SETTINGS SHUTTERS_HOME HRC_DOOR_OPEN G_GRATING_STAT);

@Glob_vals = qw('FALSE' 'TRUE' 'ENAB' 2 'A' 'HRC-I' 'FALSE' 'TRUE' 'FALSE' 'NONE');

@Globals{@Glob_keys} = @Glob_vals;
   
print STDERR "Has SCS 107 been run? (y/n)\n";
chomp($answer = <STDIN>);

if ($answer eq "y")
	{
		print STDERR "What time was SCS 107 initiated? (e.g. 2001:165:01:01:01)\n";
		chomp($i_time = <STDIN>);
	}
else
	{
		print STDERR "What is the intercept time? (e.g. 2001:165:01:01:01)\n";
		chomp($i_time = <STDIN>);
	}
	
print STDERR "Please enter the name for the global files (e.g. JUL1412)\n";
chomp($name = <STDIN>);	

$header1 = "Globals_" . $name . "_O.fot";
$header2 = "Globals_" . $name . "_V.fot";

$out1 = "/ehs/ofls/build/bin/user/mps/ops/fot_rqsts/$header1";
$out2 = "/ehs/ofls/build/bin/user/mps/ops/fot_rqsts/$header2";

open (TRP, `ls *.trp`) or die "Cannot find Translation Report.\n";
while (<TRP>) 
{
	chomp;
	if(/(\w*) == (\S*) <---/)
	{
		$Globals{$1} = $2;
		#print STDERR "$1  --->  $Globals{$1}\n";
	}
	if(/(\w*) = (\S*) <---/)
	{
		$Globals{$1} = $2;
		#print STDERR "$1  --->  $Globals{$1}\n";
	}	
	
	if ( /:\d{4}\.dot/ ) 
	{
		$DOT = 1;
	}
	
	if ( $DOT && /(\d{4}:\d{3}:\d{2}:\d{2}:\d{2}\.\d{3})/ )
	{
		$Cur_Time = $1;
		$Cur_Time_secs = time_to_seconds($1);
		#print TEST $Cur_Time . "\n";
		#print TEST sprintf("G_ACQFLG: %s G_MANFLG: %s G_SUNPOSMON: %s G_TLM_FMT: %s G_IU_ID: %s PREV_HRC_DETECTOR: %s PREV_HRC_DEF_SETTINGS: %s SHUTTERS_HOME: %s HRC_DOOR_OPEN: %s G_GRATING_STAT: %s\n\n",
								#$Globals{G_ACQFLG}, $Globals{G_MANFLG}, $Globals{G_SUNPOSMON}, $Globals{G_TLM_FMT}, $Globals{G_IU_ID}, $Globals{PREV_HRC_DETECTOR}, $Globals{PREV_HRC_DEF_SETTINGS}, $Globals{SHUTTERS_HOME}, $Globals{HRC_DOOR_OPEN}, $Globals{G_GRATING_STAT});
	}
	
	last if ($Cur_Time_secs >= time_to_seconds($i_time));
}
close(TRP);

if ($answer eq "y") 
{
	$Globals{SHUTTERS_HOME} = "'TRUE'";
	$Globals{G_ACQ_FLG} = "'FALSE'";
	$Globals{G_MANFLG} = "'TRUE'";
	$Globals{HRC_DOOR_OPEN} = "'FALSE'";
}

open(GLBO,"</ehs/ofls/build/bin/user/mps/ops/fot_rqsts/Globals_O.tmp") or die "Cannot open Globals_O.tmp.\n";
open(GLBO_OUT,">$out1") or die "Cannot open Observation output file.\n";
while (<GLBO>) 
{
	if(/! Globals.tmp/)
	{
		print GLBO_OUT "! " . $header1 . "\n";
		next;
	}
	elsif(/Template for Glob_MMMDDYY_O.fot/)
	{
		print GLBO_OUT "\n";
		next;
	}
	elsif ($_ =~ /_SET\s/) 
	{
		($junk, $key, $junk2, $val) = split;
		print GLBO_OUT "_SET $key == $Globals{$key}\n";
	}
	else 
	{
		print GLBO_OUT $_;
	}
}
close(GLB_OUT);
close(GLBO);

open(GLBV,"</ehs/ofls/build/bin/user/mps/ops/fot_rqsts/Globals_V.tmp") or die "Cannot open Globals_V.tmp.\n";
open(GLBV_OUT, ">$out2") or die "Cannot open Vehicle output file.\n";
while (<GLBV>) 
{
	if(/! Globals.tmp/)
	{
		print GLBV_OUT "! " . $header2 . "\n";
		next;
	}
	elsif(/Template for Glob_MMMDDYY_V.fot/)
	{
		print GLBV_OUT "\n";
		next;
	}
	elsif ($_ =~ /_SET\s/) 
	{
		($junk, $key, $junk2, $val) = split;
		print GLBV_OUT "_SET $key == $Globals{$key}\n";
	}
	else 
	{
		print GLBV_OUT $_;
	}
}
close(GLBV_OUT);
close(GLBV);
##########################################
##					
##	Subroutines			
##					
##########################################

## time_to_seconds - converts time from 'year:day:hour:min:sec' format to seconds from 1993
##
##	$seconds = time_to_seconds($time);	where $time is a string in the following format: "year:day:hour:min:sec"
sub time_to_seconds {
	my $input = $_[0];					# Grab input, assign to local variable
	my @time;
	my $year, $day, $hour, $min, $sec;
	my $total_seconds;
	
	@time = split(/:/, $input);
	if ($#time >= 0) {
		$year = $time[0];
		$total_seconds = ($year-1993)*31536000 + int(($year-1993)/4)*86400;
		# Account for leap second at end of 2008
		if ($year > 2008) {
			$total_seconds = $total_seconds+1;
		}
		
		if ($#time >= 1) {
			$day = $time[1];
			$total_seconds = $total_seconds + ($day-1)*86400;
		
			if ($#time >= 2) {
				$hour = $time[2];
				$total_seconds = $total_seconds + $hour*3600;
				
				if ($#time >= 3) {
					$min = $time[3];
					$total_seconds = $total_seconds + $min*60;
					
					if ($#time >= 4) {
						$sec = $time[4];
						$total_seconds = $total_seconds + $sec;
					}
				}
			}
		}
	
		return $total_seconds;
	}
	else {
		return undef;
	}
}
