# dumpeph.pl
# Dump contents of binary ephemeris files and other data
#   to determine location for state vectors within records
# Ephemeris files consists of 2800-byte records
# first record is header
# second record is dummy (spare)
# remaining records except last are ephemeris data records
# last record is sentinel record
# Usage: perl dumpeph.pl INPUT.EPH OUTPUT.csv
# Output is file of comma separated variables (csv)
# wsdavis version 03 2008-10-12 add 60 sec to HOSC time for leap second
#                               reject invalid state vectors
# wsdavis version 04 2008-11-09 improve invalid state vector rejection
# wsdavis version 05 2008-12-03 fix special case
# wsdavis version 06 2012-05-01 cleanup and update
# wsdavis version 07 2012-05-03 use alternate $DT computation
  use English;
  use Config;
  use POSIX;
  $versiondate = "2012-05-03";
  $versionnum = "7.0";
# Perl Information
  printf("Perl Version = %vd, Script Version Date: $versiondate, Script Version Num = $versionnum\n",$PERL_VERSION);
# initialization 
  print("Running Perl Script \"$PROGRAM_NAME @ARGV\"\n");
  $NumARGV = $#ARGV + 1;
  ($NumARGV > 0) or die("Intended to be used with one or two command line arguments, ".
                         "the input file name and optionally the output file name, e.g.\n".
                         "perl $PROGRAM_NAME InFileName [OutFileName]\n");
  $InFile = $ARGV[0];
  open(INFILE,$InFile) or die("File $InFile cannot be opened, error = $OS_ERROR");
  binmode(INFILE);
  if ($NumARGV > 1) {$OutFile = $ARGV[1];} # sets file for output
  else {$OutFile = "&STDOUT";} # sets STDOUT for output
  open(OUTFILE,">$OutFile") or die("File $OutFile cannot be opened, error = $OS_ERROR");
  $FALSE = 0; $TRUE = 1; $done = $FALSE; 
# bypass header data for now
  $bytesread = sysread(INFILE,$data,2800); # read & skip header record
  $bytesread = sysread(INFILE,$data,2800); # read & skip dummy record
# read & dump ephemeris vectors
  printf(OUTFILE "Perl Version = %vd, Script Version Date: $versiondate, Script Version Num = $versionnum\n",$PERL_VERSION);
  print(OUTFILE  "Perl Script \"$PROGRAM_NAME @ARGV\"\n");
  ($sec,$min,$hr,$day,$mon,$yr,$wkday,$doy) = localtime(time);
  $yr = $yr + 1900; $doy++; $mon = $mon++; 
  printf(OUTFILE "Run Time %4d:%03d:%02d:%02d:%02d\n",$yr,$doy,$hr,$min,$sec);
  printf(OUTFILE "Dump contents of ephemeris file \"$ARGV[0]\"\n");
  printf(OUTFILE "record,Offset,UTC,POS-X,POS-Y,POS-Z,VEL-X,VEL-Y,VEL-Z,deltaT-OBS\n");
  printf(OUTFILE "number,(hh:mm:ss),year:doy:hr:mi:sec,(KM),(KM),(KM),(KM/SEC),(KM/SEC),(KM/SEC),(sec)\n");
  $done = $FALSE; $recnum = 0; $vecnum = 0;
  do
  {
    $bytesread = sysread(INFILE,$data,2800); # read next data record
    @array = RecordToEPHData($data); # convert to array
    if ((abs($array[4]) > 1.0E15) or ($bytesread != 2800)) # check for end of data
    {
      $done = $TRUE;
    } 
    else
    {
      $recnum++; # increment record number
#     get time of first vector      
      ($yr,$mon,$day,$hr,$min,$sec) = DoubTimeToParts($array[0]); 
      $doy = $array[1]; # day of year
      $sod = $array[2]; # seconds of day
      $hr = floor($array[2]/3600.0); # hour of day
      $min = floor(($array[2] - $hr*3600.0)/60.0); # min of hour
      $sec = $array[2] - $hr*3600.0 - $min*60.0; # sec of min 
      $timestr = sprintf("%4d:%03d:%02d:%02d:%06.3f",$yr,$doy,$hr,$min,$sec); # HOSC time string
      $mjd = DateToMJD($yr,$mon,$day); # modified Julian day
      $MJD1985 = 46066; # mjd of 1985:001:00:00:00
      $sec1985 = ($mjd - $MJD1985)*86400 + $sod; # sec from 1985, excluding leap sec
#     get time between vectors      
      $delT = $array[3];
#     get each state vector and write to file      
      for ($n = 4; $n < 303; $n +=6)  # loop 50 state vectors, 6*50 = 300
      { 
        if ((abs($array[$n+0]) < 1.0E10) and (abs($array[$n+1]) < 1.0E10) and (abs($array[$n+2]) < 1.0E10) and 
            (abs($array[$n+3]) < 1.0E10) and (abs($array[$n+4]) < 1.0E10) and (abs($array[$n+5]) < 1.0E10) and
            not((abs($array[$n+0]) < 1.0E-3) and (abs($array[$n+1]) < 1.0E-3) and (abs($array[$n+2]) < 1.0E-3)) and
            not((abs($array[$n+3]) < 1.0E-6) and (abs($array[$n+4]) < 1.0E-6) and (abs($array[$n+5]) < 1.0E-6))
           ) # check for valid data
        { 
          $vecnum++;
          ($pos[0],$pos[1],$pos[2]) = ($array[$n+0],$array[$n+1],$array[$n+2]);
          ($vel[0],$vel[1],$vel[2]) = ($array[$n+3],$array[$n+4],$array[$n+5]);
          if (($n == 4) and ($recnum == 1)) { @posprev = @pos; @velprev = @vel; }
#         compute approximate time between vectors assuming constant acceleration
          $dt[0] = ($pos[0] - $posprev[0])/($vel[0] + $velprev[0])*2;          
          $dt[1] = ($pos[1] - $posprev[1])/($vel[1] + $velprev[1])*2;          
          $dt[2] = ($pos[2] - $posprev[2])/($vel[2] + $velprev[2])*2;
#         compute weights
          $wt[0] = abs($pos[0] - $posprev[0]);          
          $wt[1] = abs($pos[1] - $posprev[1]);          
          $wt[2] = abs($pos[2] - $posprev[2]);          
#         compute weighted sum
          if ($vecnum > 1)
             {$DT = ($dt[0]*$wt[0] + $dt[1]*$wt[1] + $dt[2]*$wt[2])/($wt[0]+$wt[1]+$wt[2]);}
          else {$DT = 0;}
#         Compute alternate $DT
          $Dpos = sqrt(($pos[0] - $posprev[0])*($pos[0] - $posprev[0]) + ($pos[1] - $posprev[1])*($pos[1] - $posprev[1]) + ($pos[2] - $posprev[2])*($pos[2] - $posprev[2]));
          $Dvel = sqrt(($vel[0] + $velprev[0])*($vel[0] + $velprev[0]) + ($vel[1] + $velprev[1])*($vel[1] + $velprev[1]) + ($vel[2] + $velprev[2])*($vel[2] + $velprev[2]))/2.0;
          $DT = $Dpos/$Dvel;
#         Compute offset time from first state vector of record
          $offsec = ($n-4)*$delT/6;          
          $offhr = floor($offsec/3600);
          $offsec = $offsec - $offhr*3600;
          $offmin = floor($offsec/60);
          $offsec = $offsec - $offmin*60;
          $offset = sprintf("%02d:%02d:%02d",$offhr,$offmin,$offsec);
#         write state vector data to file          
          printf(OUTFILE "%6d, %s, %s, %12.4f, %12.4f, %12.4f, %12.8f, %12.8f, %12.8f, %10.3f\n",
                 $recnum,$offset,$timestr,$pos[0],$pos[1],$pos[2],$vel[0],$vel[1],$vel[2],$DT);
#         prepare for next loop                 
          @posprev = @pos; @velprev = @vel;
          $sec1985 = $sec1985 + $delT;
          $timestr = secref2HOSCTime($sec1985,$MJD1985); # HOSC time string
          if ($timestr eq '2006:001:00:00:00.000') {$timestr = '2005:365:23:59:60.000';} 
          if ($timestr eq '2009:001:00:00:00.000') {$timestr = '2008:366:23:59:60.000';} 
          if ($timestr eq '2012:183:00:00:00.000') {$timestr = '2012:182:23:59:60.000';} 
        } # end of if for state vector
      } # end of loop over state vectors within record 
    } # end of loop over non-sentinal records
  } # end of loop over records
  until $done;   
  print("Done! $vecnum vectors written to \"$OutFile\"\n");
  close(INFILE);
  close(OUTFILE);

#=======================================================================
# ($yr,$mon,$day,$hr,$min,$sec) = DoubTimeToParts($date) 
# convert $date as real number yymmdd.hhmmsssss to individual parts
  sub DoubTimeToParts # ($date)
  {
    my($date) = shift(@ARG);
    my($yr)   = floor($date/10000);
    my($mon)  = floor(($date - $yr*10000)/100);
    my($day)  = floor($date - $yr*10000 - $mon*100);
    my($time) = ($date - $yr*10000 - $mon*100 - $day)*1000000;
    if ($yr <51) { $yr = $yr + 2000; } else { $yr = $yr + 1900; }
    my($hr)  = floor($time/10000);
    my($min) = floor(($time - $hr*10000)/100);
    my($sec) = $time - $hr*10000 - $min*100;
    my(@parts) = ($yr,$mon,$day,$hr,$min,$sec);
    return(@parts);
  }   
  
#-----------------------------------------------------------------------
# "year:doy:hr:mm:ss.sss" = YrDoySodtoHOSCtime($yr,$doy,$sod)
# convert year, day-of-year, and sec-of-day to HOSC time format
  sub YrDoySodtoHOSCtime # ($yr,$doy,$sod)
  {
    my($yr)  = shift(@ARG);
    my($doy) = shift(@ARG);
    my($sod) = shift(@ARG);
    my($hr)  = floor($sod/3600.0);
    my($min) = floor(($sod - $hr*3600.0)/60.0);
    my($sec) = $sod - $hr*3600.0 - $min*60.0;
    my($timestring) = sprintf("%4d:%03d:%02d:%02d:%06.3f",$yr,$doy,$hr,$min,$sec);
    return($timestring);
  }   
  
#-----------------------------------------------------------------------
# "year:doy:hr:mm:ss.sss" = secref2HOSCTime($secref,$refmjd)
# convert sec from ref date to "year:doy:hr:mm:ss.sss"
# input sec from ref date 
#       reference date, modified Julian date (MJD)
# output time string in HOSCGMT format year:doy:hr:mm:ss.sss
# NON-Leap-Second version!  Future version will have LeapSec array as an ARG
# some common MJDs 
# $MJD1900 = 15020; # MJD of 1900-01-01
# $MJD1950 = 33282; # MJD of 1950-01-01
# $MJD1958 = 36204; # MJD of 1958-01-01
# $MJD1970 = 40587; # MJD of 1970-01-01
# $MJD1985 = 46066; # MJD of 1985-01-01
# $MJD1990 = 47892; # MJD of 1990-01-01
# $MJL1998 = 51178; # MJD of 1998-12-31 contains 86401 sec
# $MJD1999 = 51179; # MJD of 1999-01-01
# $MJD2000 = 51544; # MJD of 2000-01-01
# $MJD2005 = 53371; # MJD of 2005-01-01
# $MJL2005 = 53735; # MJD of 2005-12-31 contains 86401 sec  
# $MJD2006 = 53736; # MJD of 2006-01-01
# $MJD2008 = 54466; # MJD of 2008-01-01
# $MJL2008 = 54831; # MJD of 2008-12-31 contains 86401 sec
# $MJD2009 = 54832; # MJD of 2009-01-01
# $MJD2010 = 55197; # MJD of 2010-01-01
# $MJD2011 = 55562; # MJD of 2011-01-01
# $MJD2012 = 55927; # MJD of 2012-01-01
# $MJM2012 = 56108; # MJD of 2012-06-30 contains 86401 sec
# $MJD2013 = 56293; # MJD of 2013-01-01

  sub secref2HOSCTime # ($secref,$refmjd)
  {
    my($secref,$refmjd,$sec1970,$timestring,$MJD1970,$time,$frac);
    my($sec,$min,$hr,$day,$mo,$yr,$wkday,$doy,$lsDST);
    $secref = shift(@ARG);
    $refmjd = shift(@ARG);
    $MJD1970 = 40587; # MJD of 1970-01-01
    $sec1970 = $secref + ($refmjd - $MJD1970)*86400;
    $time = int($sec1970);
    $frac = $sec1970 - $time;
    ($sec,$min,$hr,$day,$mo,$yr,$wkday,$doy,$lsDST) = gmtime($time);
    $mo = $mo + 1; $yr = $yr + 1900; $doy = $doy + 1;
    $sec = $sec + $frac;
    $timestring = sprintf("%4d:%03d:%02d:%02d:%06.3f",$yr,$doy,$hr,$min,$sec);
    return($timestring);
  }

#-----------------------------------------------------------------------
# ($yr,$mo,$day) = MJDtoDate($mjd)
# convert modified Julian date to calender date array
# input modified Julian date integer
# output calender date array ($yr,$mon,$day)
  sub MJDtoDate # ($mjd)
  {
    my($date);
    my($sec,$min,$hr,$day,$mo,$yr,$wkday,$doy,$lsDST);
    my($mjd) = shift(@ARG);
    my($MJD1970) = 40587; # MJD of 1970-01-01
    my($time) = ($mjd - $MJD1970)*86400; # seconds from 1970 excluding leap sec 
    ($sec,$min,$hr,$day,$mo,$yr,$wkday,$doy,$lsDST) = gmtime($time);
    $mo = $mo + 1; $yr = $yr + 1900; $doy = $doy + 1;
    my(@date) = ($yr,$mo,$day);
    return(@date);
  }

#-----------------------------------------------------------------------
# $mjd = DateToMJD($yr,$mon,$day) 
# compute modified julian day from $yr,$mon,$day
# 1900 < year < 2100                  }
# from Almanac for Computers          }

  sub DateToMJD # ($mjd)
  {
    my($yr)  = shift(@ARG);
    my($mon) = shift(@ARG);
    my($day) = shift(@ARG);
    my($mjd) = 367*$yr -
               int(7*($yr+int(($mon+9)/12))/4) +
               int(275*$mon/9) +
               $day + (1721013.5 - 2400000.5);
    return($mjd);
  }  

#-----------------------------------------------------------------------
# split $data into array of 350 double precision numbers
  sub RecordToDouble # ($data);
  {
    my(@bytes,@work,$n);
    @bytes = split(//,$ARG[0]);
    for ($n = 0; $n < 350; $n +=1) 
    {
      $work[$n] = unpack("d",join("",reverse(@bytes[$n..($n+7)])));
    } 
    return(@work);
  }

#-----------------------------------------------------------------------
# split state vector record into array of 350 doubles and integers
  sub RecordToEPHData # ($data);
  {
    my(@bytes,@work,$n);
    my($DULKM) = 1.0E-4;
    my($DULKMS) = 864.0E-4;
    @bytes = split(//,$ARG[0]); # array of bytes
    $work[0] = unpack("d",join("",reverse(@bytes[0...7])));   # YYMMDD of first vector
    $work[1] = unpack("i",join("",reverse(@bytes[8...15])));  # DOY of first vector (day)
    $work[2] = unpack("i",join("",reverse(@bytes[16...23]))); # SOD of first vector (sec)
    $work[3] = unpack("d",join("",reverse(@bytes[24...31]))); # sec between vectors (sec)
    for ($n = 4; $n < 303; $n +=6)  # get 50 state vectors, 6*50 = 300
    {
      $work[$n+0] = unpack("d",join("",reverse(@bytes[8*($n+0)..(8*($n+0)+7)])))/$DULKM;
      $work[$n+1] = unpack("d",join("",reverse(@bytes[8*($n+1)..(8*($n+1)+7)])))/$DULKM;
      $work[$n+2] = unpack("d",join("",reverse(@bytes[8*($n+2)..(8*($n+2)+7)])))/$DULKM;
      $work[$n+3] = unpack("d",join("",reverse(@bytes[8*($n+3)..(8*($n+3)+7)])))/$DULKMS;
      $work[$n+4] = unpack("d",join("",reverse(@bytes[8*($n+4)..(8*($n+4)+7)])))/$DULKMS;
      $work[$n+5] = unpack("d",join("",reverse(@bytes[8*($n+5)..(8*($n+5)+7)])))/$DULKMS;
    } 
    return(@work);
  }
  
