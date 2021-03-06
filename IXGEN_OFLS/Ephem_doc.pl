`#!/usr/bin/perl

#########################################################################################
# ephem_doc.pl
#
# orig:   Sabina Bucher   6/14/01
# 3.2  :  Sabina Bucher   2/27/02    Updated to better handle year rollover
#         K. Marsh        4/1/03     Changed default printer to prmsn
#
########################################################################################
#
# This script checks for the most recent state vector and orbit events and prints out the 
# documentation for Ephemeris Generation.  It also adds the newest state vectors to the end 
# of the mission life state vector set.
#
#########################################################################################

$sv_temp= </ehs/ofls/build/bin/user/ix_*/SV*>;

if ($sv_temp=~ /SV/) {

    print "I have found $sv_temp, is this the correct State Vector?\n";

    $ans = <>;

    chop $ans;


  if ($ans =~ /^n/ || $ans =~ /^N/)

	{print "Please enter the full path and name of the State Vector you would like to use.\n";

	 $sv_file=<>;

	 chop $sv_file;

	 $yn=1}



	else 

	{ $sv_file = $sv_temp;}

}



else { print "Please enter the full path and name of the State Vector you would like to use.\n";

       $sv_file=<>;

       chop $sv_file}


($crap, $sv_name)= split ('/SV', $sv_file);

$root=$sv_name;

$sv_name = SV.$sv_name;

$root=~ s/\d\d\d\d\d\d.dsn//i;

$first=0;

open (SVF, "<$sv_file");

    while (<SVF>) {

	$line=$_;

	$line=~ s/126015101\d\d\d//;

	$line =~ s/00046559000000230//;

	$line =~ s/-/ -/g;

	($time, $x, $y, $z, $vx, $vy, $vz)=split (' ',$line);

	$time_orig=$time;

	$time=~ s/(\d)(\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d\d)/200$1:$2:$3:$4:$5.$6/;

	if ($first==0) 

	{ $time1=$time;

	  $time_orig1=$time_orig;

	  $x1=$x;

	  $y1=$y;

	  $z1=$z;

	  $vx1=$vx;

	  $vy1=$vy;

	  $vz1=$vz;

	  $first=1;

	  $x1=$x1/1000;

	  $y1=$y1/1000;

	  $z1=$z1/1000;

	  $vx1=$vx1/1000000;

	  $vy1=$vy1/1000000;

	  $vz1=$vz1/1000000;
      }

    }

close (SVF);


print "Will eclipse times be computed in orbit events generation?\n";

$ecl = <>;

chop $ecl;

if ($ecl=~/[yY]/) {

    print "Enter E for earth Shadow, L for Lunar Shadow or B for Both\n";

    $type=<>;

    chop $type;

    if ($type =~ /[Ee]/) { $eclipses= "Earth Shadow"}

    elsif ($type =~ /[Ll]/) { $eclipses= "Lunar Shadow"}

    elsif ($type =~ /[Bb]/) { $eclipses= "Earth Shadow      Lunar Shadow"}

    else { print "I did not understand your answer, skipping eclipses."}}

elsif ($ecl=~/[Nn]/) {  $eclipses = "None"}

else { print "I did not understand your answer, skipping eclipses.\n"}
	

print "Will OBC Coeficients be Generated?\n";

$obc = <>;

chop $obc;

if ($obc =~ /[Yy]/)

{  $OBC = YES;

   $ofl=DE.$root.".ofl"

}

elsif ($obc =~ /[nN]/) {$OBC=NO}

else { print "I did not understand your answer, skipping OBC section.\n";}


      
open (OUT, ">/ehs/ofls/build/bin/iss/ephemeris/definitive/doc_$root.txt") || die "cannot create doc_$root.txt: $!";

print OUT"

                      OFLS Ephemeris Generation Form



Definitive Ephemeris File Name:         DE$root.EPH
Predictive Ephemeris File Name:         PE$root.EPH
Definitive Orbit Events File Names:     DO$root.idx, DO$root.dat
Predictive Orbit Events File Names:     PO$root.idx, PO$root.dat

DSN State Vector Used:     $sv_name

Start Time:  $time1   Stop Time:  $time


Number of History Days:  20     Number of Predictive Days:  2


Cartesian Elements:

         x:   $x1         y:   $y1         z:   $z1

         Vx:  $vx1          Vy:  $vy1         Vz:  $vz1

Epoch Time:  $time1


Orbit Events Computed:


DSN Coverage Times:   Stations:    16, 24, 27, 34, 46, 54, 66


Radiation Times:      Thresholds:  electron:  .5 MeV 10 part/cm2*sec
                                   proton:    25 MeV 10 part/cm2*sec


Altitude Zones:       Zones(km):   27427  to 27429
                                   106377 to 106379


Eclipses:             $eclipses



OBC Coeficients Generated:   $OBC

OFLS File Name:  $ofl

FOT File Name:   



STK Satellite Name:   DSN$root .sa, .sa3

Comments:

";

close (OUT);

system "cp $sv_file /ehs/ofls/build/bin/user/iss/svdsn";

@LONGSV=</ehs/ofls/build/bin/user/iss/svdsn/SV_99219*>;

sort @LONGSV;

$def=pop @LONGSV;

print "$def\n";  # if script dies delete this line

$new = $root+8;

$old_end=$time_orig1;


open (NEW,">/ehs/ofls/build/bin/user/iss/svdsn/SV_99219_0$new.DSN") || die "cannot open SV_99219_0$new:  $!";

open (OLD, "<$def") || die "cannot open $def:  $!";

$stop=0;

while (<OLD>) {


    if ($_=~ /$old_end/) {$stop=1};

    if ($stop==0) {print NEW $_}};



close (OLD);

	if ($stop==0) { print "

Check new long state vector.  
I could not match the start time of the current state vector to any time in $def.
It is likly that the time of the first vector shifted by 4 hours.
Instead of replacing data from $def the new data was simply added to the end.
Edit SV_99219_0$new.DSN to remove the data that should have been replaced by this run. 

" 

}

    $stop=0;

open (SVF2, "<$sv_file") || die "cannot open $sv_file:  $!";

while (<SVF2>) {

    if ($_=~ /126015101023/) {$stop=1};

    if ($stop==0) {print NEW $_}};
	

close (SVF2);

close (NEW);

# system "lp -d prmsn /ehs/ofls/build/bin/iss/ephemeris/definitive/doc_$root.txt";

 system "lpr /ehs/ofls/build/bin/iss/ephemeris/definitive/doc_$root.txt";
 
# system "fold $sv_file | lp -d prmsn"

