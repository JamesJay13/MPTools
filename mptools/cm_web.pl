#!/usr/bin/perl
use File::Find;
use File::Copy;
use File::stat;
use Time::localtime;

#$Revision: 2.10 $
#$Date: 2006/09/06 21:10:08 $
##########################################################################
# cm_web.pl 
# Version 0.1
#
# Created by: Steve Mancini
#
# This script is designed to make web publication of Command Management
# products as easy and automated as possible.  Web page format is set
# by modifying the file cmwebtemplate.txt. The cm load will also be put in
# its correct location.
#
# Required input files:
# ---------------------
#  cmwebtemplate.txt
# 
#
# Change Log
# ----------
#
##########################################################################

@dir_list = ();
@tarballs = ();

 
# Determine CM directory name

@dir_list = glob ('*');
find(\&wanted, @dir_list);

for $a (0 .. $#tarballs)
{
  $untar = `tar -zxvf $tarballs[$a]`;
	find (\&needed, @names[$a]);
	
	open(TMP,"</home/mission/Backstop/cm/cmwebtemplate.txt");
	open(OUT,">/home/mission/Backstop/cm/$names[$a]/$names[$a].html");
	
	while(<TMP>) 
	{
    		$line = $_;

    		if ($line =~ /Page Title/ or $line =~ /Heading/)
    		{
			print OUT "$names[$a]\n";
    		}
    		elsif ($line =~ /Sum Files/)
    		{
			for $b (0 .. $#dir_name) 
			{
	    			if ($dir_name[$b] =~ /\.sum/)
	    			{
					chomp ($dir_name[$b]);
					print OUT "<dd> <a href=\"./$dir_name[$b]\"> $dir_name[$b] </a>\n";
	    			}
			}	
   		}	

    		elsif ($line =~ /Timel Report/)
    		{
			for $b (0 .. $#dir_name) 
			{
	    			if ($dir_name[$b] =~ /\.tlr/)
	    			{
					chomp ($dir_name[$b]);
					print OUT "<dd> <a href=\"./$dir_name[$b]\"> $dir_name[$b] </a>\n";
	    			}
			}
    		}
    

    		elsif ($line =~ /Trans Report/)
    		{
			for $a (0 .. $#dir_name) 
			{
	    			if ($dir_name[$a] =~ /\.trp/)
	    			{
					chomp ($dir_name[$a]);
					print OUT "<dd> <a href=\"./$dir_name[$a]\"> $dir_name[$a] </a>\n";
	    			}
			}
    		}
    		elsif ($line =~ /Err Files/)
    		{
			for $a (0 .. $#dir_name) 
			{
	    			if ($dir_name[$a] =~ /\.err/)
	    			{
					chomp ($dir_name[$a]);
					print OUT "<dd> <a href=\"./$dir_name[$a]\"> $dir_name[$a] </a>\n";
	    			}
			}
   		}
    		elsif ($line =~ /Cmd Loads/)
    		{
			for $a (0 .. $#dir_name) 
			{
	    			if ($dir_name[$a] =~ /\.cld/)
	    			{
					chomp ($dir_name[$a]);
					print OUT "<dd> <a href=\"./$dir_name[$a]\"> $dir_name[$a] </a>\n";
	    			}
			}
   		}
  
   		elsif ($line =~ /Inpt Files/)
   		{
   			for $a (0 .. $#dir_name) 
			{
	    			if ($dir_name[$a] =~ /\.fot/)
	    			{
					chomp ($dir_name[$a]);
					print OUT "<dd> <a href=\"./$dir_name[$a]\"> $dir_name[$a] </a>\n";
	    			}
	    			elsif ($dir_name[$a] =~ /\.ofl/)
	    			{
					chomp ($dir_name[$a]);
					print OUT "<dd> <a href=\"./$dir_name[$a]\"> $dir_name[$a] </a>\n";
	    			}
	    			elsif ($dir_name[$a] =~ /\.smf/)
	    			{
					chomp ($dir_name[$a]);
					print OUT "<dd> <a href=\"./$dir_name[$a]\"> $dir_name[$a] </a>\n";
	    			}
				elsif ($dir_name[$a] =~ /\.dot/)
	    			{
					chomp ($dir_name[$a]);
					print OUT "<dd> <a href=\"./$dir_name[$a]\"> $dir_name[$a] </a>\n";
	    			}
				else
				{
					next;
				}
			}
   		}


    		else
    		{
			print OUT $line;
    		}
    
	}
	close(OUT);
	close(TMP);
	
	@dir_name = ();

	print STDERR "\n$names[$a] HTML File created. Moving load to its appropriate location...\n\n";

	open(IN, "$names[$a]/$names[$a].sum") || die "$!";

	while (<IN>)
	{
	
		if (/CFSW VERSION =/)
		{
			$type = "FSW_LOADS";
		}
		if (/CMAN VERSION/ || /CRPT VERSION/)
		{
			$type = "ENG_LOADS";
		}
		
		if(/^\s{29}\d{4}:\d{3}:\d{2}:\d{2}:\d{2}\.\d{3}/ && ($type eq "FSW_LOADS"))
		{
			chomp(($time) = $_ =~ /\s{29}(.*)/);
			@date = split(/:/, $time);
			     
		}
		
		if (/EXECUTION BEGIN TIME/)
		{
			($date) = $_ =~ /TIME:(.{21})/;
			@date = split (/:/, $date);	
		}
		
	}
	close(IN);
	
	
	if (($date[0] =~ /2000/) || ($date[0] =~ /2004/) || ($date[0] =~ /2008/) || ($date[0] =~ /2012/) || ($date[0] =~ /2016/) || ($date[0] =~ /2020/))
	{	
		for $b (1 .. 31)
		{
			if ($date[1] == $b)
			{
				$month = "Jan";	
			}
		}
		for $b (32 .. 60)
		{
			if ($date[1] == $b)
			{
				$month = "Feb";		
			}
		}
		for $b (61 .. 91)
		{
			if ($date[1] == $b)
			{
				$month = "Mar";		
			}
		}
		for $b (92 .. 121)
		{
			if ($date[1] == $b)
			{
				$month = "Apr";		
			}
		}
		for $b (122 .. 152)
		{
			if ($date[1] == $b)
			{
				$month = "May";		
			}
		}
		for $b (153 .. 182)
		{
			if ($date[1] == $b)
			{
				$month = "Jun";		
			}
		}
		for $b (183 .. 213)
		{
			if ($date[1] == $b)
			{
				$month = "Jul";		
			}
		}
		for $b (214 .. 244)
		{
			if ($date[1] == $b)
			{
				$month = "Aug";	
			}
		}
		for $b (245 .. 274)
		{
			if ($date[1] == $b)
			{
				$month = "Sep";		
			}
		}
		for $b (275 .. 305)
		{
			if ($date[1] == $b)
			{
				$month = "Oct";		
			}
		}
		for $b (306 .. 335)
		{
			if ($date[1] == $b)
			{
				$month = "Nov";		
			}
		}
		for $b (336 .. 366)
		{
			if ($date[1] == $b)
			{
				$month = "Dec";		
			}
		}
	}

	else
	{
		for $b (1 .. 31)
		{
			if ($date[1] == $b)
			{
				$month = "Jan";		
			}
		}
		for $a (32 .. 59)
		{
			if ($date[1] == $a)
			{
				$month = "Feb";		
			}
		}
		for $a (60 .. 90)
		{
			if ($date[1] == $a)
			{
				$month = "Mar";		
			}
		}
		for $a (91 .. 120)
		{
			if ($date[1] == $a)
			{
				$month = "Apr";		
			}
		}
		for $a (121 .. 151)
		{
			if ($date[1] == $a)
			{
				$month = "May";		
			}
		}
		for $a (152 .. 181)
		{
			if ($date[1] == $a)
			{
				$month = "Jun";		
			}
		}
		for $a (182 .. 212)
		{
			if ($date[1] == $a)
			{
				$month = "Jul";		
			}
		}
		for $a (213 .. 243)
		{
			if ($date[1] == $a)
			{
				$month = "Aug";		
			}
		}
		for $a (244 .. 273)
		{
			if ($date[1] == $a)
			{
				$month = "Sep";		
			}
		}
		for $a (274 .. 304)
		{
			if ($date[1] == $a)
			{
				$month = "Oct";		
			}
		}
		for $a (304 .. 334)
		{
			if ($date[1] == $a)
			{
				$month = "Nov";		
			}
		}
		for $a (335 .. 365)
		{
			if ($date[1] == $a)
			{
				$month = "Dec";		
			}
		}
	}

	unless (-e "/home/mission/Backstop/cm/$type/$date[0]/$month")
	{
		$mkdir = `mkdir /home/mission/Backstop/cm/$type/$date[0]/$month`;
	}
				
	$mkdir = `mkdir /home/mission/Backstop/cm/$type/$date[0]/$month/$names[$a]`;
	$move = `mv $names[$a] /home/mission/Backstop/cm/$type/$date[0]/$month/$names[$a]`;


	@date = ();
	$cleanup = `rm -r $tarballs[$a]`;
}




sub wanted
{
     $file = $_;
     if ($file =~ /\.tar/)
     {
	push @tarballs, "$file";
	($name = $file) =~ s/\.[^.]+$//;
	$name =~ s/\.[^.]+$//;	
	push @names, "$name";
     }
}

sub needed
{
     $file = $_;     
     push @dir_name, "$file";	
}
