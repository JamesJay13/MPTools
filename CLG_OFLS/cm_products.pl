#!/usr/bin/perl
use File::Find;
use File::Copy;
use File::Basename;
use Net::FTP;

# $Revision: 1.0 $
# $Date: 2011-07-12 11:51:00 $   


####################################################################
#  NAME:  cm_products.pl
#
#  Created by: Steve Mancini
#
#  DESCRIPTION: This script will bring together the input and
#               output files for non-weekly command loads to be
#               moved to GRETA. The files will be renamed into the
#               correct format and then tarred so they can be copied
#               to GRETA 
#    
#  HISTORY:
#    Date	   Author	 Description
#  ____________ ____________    ________________________
#
#    07-12-2011	 Steve Mancini	   Original Version
#    06-08-2012	 Steve Mancini     Maintenance
#
#####################################################################



######################################################################
#Gathering Information for FTP transfer


print "Please input your LUCKY username:\n";
chomp($user = <>);
print "Please input your password:\n";
system("stty -echo");
chomp($pass = <>);
system("stty echo");
#######################################################################
$repeat = "y";

while($repeat eq "y")
{
	print "PROCESSING...\n";

	#Find input files
	$path = `pwd`;
	chomp ($path);
	$dir = basename $path; #gets the name of the directory
	chomp ($dir);
	
	@sum_files = glob ("*.sum");
	find(\&wanted, @sum_files);

	for $a (0 .. $#directories)
	{
    	if ($dir =~ /^$directories[$a]$/)
    	{
        	$sum = $directories[$a] . '.sum';
    	}
	}

	open (IN, "$sum");

	while (<IN>)
	{
    	if (/FOT REQUEST DIRECTORY PATH/)
    	{
        	($junk, $f_rqst_path) = split ('= ', $_);
        	chomp ($f_rqst_path);
    	}

    	if (/OFLS REQUEST DIRECTORY PATH/)
    	{
    		($junk, $f_rqst_path) = split ('=', $_);
			chomp ($f_rqst_path);
    	}

		if (/INPUT DOT FILE/)
		{
			($junk, $f_rqst_path) = split ('=', $_);
			chomp($f_rqst_path);
			@parts = split('/',$f_rqst_path);
			$in_file = @parts[$#parts]; 
		}

    	if (/INPUT FOT REQUEST FILE/)
    	{
        	($junk, $in_file) = split ('= ', $_);
        	chomp($in_file); 
    	}

    	if (/INPUT OFLS REQUEST FILE/)
    	{
    		($junk, $in_file) = split ('= ', $_);
        	chomp($in_file);	
    	}

    	if (/SOFTWARE LOAD UPDATE FILE/)
    	{
        	($junk, $in_file) = split ('= ', $_);
        	chomp($in_file);
    	}
	}
	close (IN);

	$mkdir = `mkdir $dir`;
	$input_path = `find $f_rqst_path -name '$in_file'`;
	chomp ($input_path);
	$new_path = $path . '/' . $dir;
	chomp($new_path);
	$input_copy = `cp -v $input_path $new_path`;

	@sum_file = `ls *.sum 2> /dev/null`;
	@tlr_file = `ls *.tlr 2> /dev/null`;
	@trp_file = `ls *.trp 2> /dev/null`;
	@err_file = `ls *.err 2> /dev/null `;
	@cld_file = `ls *.cld 2> /dev/null `;
	@smf_file = `ls *.smf 2> /dev/null`;
	@fot_file = `ls *.fot 2> /dev/null `;
	@ofls_file = `ls *.ofl 2> /dev/null`;

	for $a (0 .. $#sum_file)
	{
    	chomp ($sum_file[$a]);
    	$copy1 = `cp $sum_file[$a] $dir` && die "Couldn't copy $sum_file[$a]:$!";
	}
	for $a (0 .. $#tlr_file)
	{   
    	chomp ($tlr_file[$a]);
    	$copy2 = `cp $tlr_file[$a] $dir` && die "Couldn't copy $tlr_file[$a]:$!";
	}
	for $a (0 .. $#trp_file)
	{   
    	chomp ($trp_file[$a]);
    	$copy3 = `cp $trp_file[$a] $dir` && die "Couldn't copy $trp_file[$a]:$!";
	}
	for $a (0 .. $err_file)
	{   
    	chomp ($err_file[$a]);
    	$copy4 = `cp $err_file[$a] $dir` && die "Couldn't copy $err_file[$a]:$!";
	}
	for $a (0 .. $#cld_file)
	{   
    	chomp ($cld_file[$a]);
    	$copy5 = `cp $cld_file[$a] $dir` && die "Couldn't copy $cld_file[$a]:$!";
	}
	for $a (0 .. $#smf_file)
	{   
    	chomp ($smf_file[$a]);
    	$copy6 = `cp $smf_file[$a] $dir` && die "Couldn't copy $smf_file[$a]:$!";
    	$remove_input = `rm $smf_file[$a]`;
	}
	for $a (0 .. $#fot_file)
	{   
    	chomp ($fot_file[$a]);
    	$copy7 = `cp $fot_file[$a] $dir` && die "Couldn't copy $fot_file[$a]:$!";
    	$remove_input = `rm $fot_file[$a]`;
	}
	for $a (0 .. $#ofls_file)
	{   
    	chomp ($ofls_file[$a]);
    	$copy7 = `cp $ofls_file[$a] $dir` && die "Couldn't copy $ofls_file[$a]:$!";
    	$remove_input = `rm $ofls_file[$a]`;
	}


	@contents = glob ('*');
	for $a (0 .. $#contents)
	{
    	if ($dir =~ /^$contents[$a]$/)
    	{
    		$rename_dir = `rename : _ $dir` && die "$!";
			$old_dir = $dir;
			($dir) =~ s/:/_/g;	    
    	}
	}

	foreach (`find $path/$dir -name "*:*"`)
	{
    		chop();
		$orig_filename = $_;
		s/:/_/g;

		@junkers = split (/\//, $_);
		@junkers2 = split (/\//, $orig_filename);

		$rename_files = `mv $path/$dir/$junkers2[10] $path/$dir/$junkers[10]`; 
	}

	$tar = `tar -cvf $dir\.tar $dir`;
	$gzip = `gzip $path/$dir\.tar`;

	$removal = `rm -rf $dir`;

	$tartomove = $dir . '.tar.gz';

	$ftp = Net::FTP->new("lucky") or die "Cannot connect to server:  Tarball has not been moved to LUCKY. Please move manually...  $@\n\n\n";
	$ftp->login($user, $pass) or die "Cannot Login: Tarball has not been moved to LUCKY. Please move manually...  \n\n\n", $ftp->message;
	$ftp->put("./$tartomove") or die "PUT failed: Tarball has not been moved to LUCKY. Please move manually...  \n\n\n", $ftp->message;
	$ftp->quit;

	print 'Tarball Created and is now in your LUCKY folder...Move to GRETA to continue process.';
	print "\n\n\n";

	$tarremoval = `rm $tartomove`;

	print "Do you have another product to move? y/n \n";
	$repeat = <>;
	chomp $repeat;

	if($repeat eq "y")
	{
		print "Please enter the product you would like move (Enter just the the folder name, not entire path):\n";
		$next_dir = <STDIN>;
		chomp $next_dir;

		while($next_dir eq "")
		{
			print "Please enter the product you would like move (Enter just the the folder name, not entire path):\n";
			$next_dir = <STDIN>;
			chomp $next_dir;
		}

		if($next_dir ne "")
		{
			$dir_new = "/usr/ehs/ofls/build/bin/cm/output/" . $next_dir;
			chdir($dir_new) or die "DIDN'T WORK, DAMMIT!\n";
		}	
	}
}

	
sub wanted
{
     $file = $_;
     if ($file =~ /\.sum/)
     {
        $file =~ s/\..*//;
        push @directories, "$file";
     }
}

