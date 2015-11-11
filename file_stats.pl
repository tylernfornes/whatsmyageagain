#!/usr/bin/perl 
  
############################################## 
# System Design and Performance 
#  The getter of things 
# 
# Ben Morse and Tyler Fornes - March 17th 2014
############################################## 
  
use strict; 
use warnings; 
use Date::EzDate; 
use File::DirWalk; 
use File::stat;
use Cwd;
use Date::Parse;
use Config;
use List::Util qw(sum);

################################################
my $OSVER;
$OSVER = $Config{osname};

if ($OSVER == "linux"){
	$ARGV[0] = "/home";
}

elsif ($OSVER == "WIN32"){
	$ARGV[0] = "C:/Documents&Settings";
}
elsif ($OSVER == "unix"){
	$ARGV[0] = "~";
}

$ARGV[1] = "02/21/2020";
$ARGV[2] = "01:00";

################################################
  
  
# I know these regex implementations do not check for proper values, only 
# proper formatting. 
die("Invalid format for date") unless ($ARGV[1] =~ /^[0-9]{0,2}\/[0-9]{1,2}\/[0-9]{4}$/); 
die("Invalid format for time") unless ($ARGV[2] =~ /^[0-9]{1,2}:[0-9]{1,2}(:[1-9]{1,2})?$/); 
  
# Initialize our DirWalk object 
my $dir = new File::DirWalk; 
$dir->onFile(\&checkTime); 
  
# Initialize the EzDate object we will be comparing files to 
my $compare_time = Date::EzDate->new($ARGV[1]." ".$ARGV[2]); 
my $today_date = Date::EzDate->new(); 
my $filesize = 0;
my $length = 0;
my @sizeArray;
my $totalfiles = 0;
my $mbcounter = 0;
my $mbcounter2 = 0;
my $mbcounter3 = 0;
my $mbcounter4 = 0;
my $mbcounter5 = 0;
my $less_one_count = 0;
my $between_one_two_count = 0;
my $over_two_count = 0;
my $totalfilecount = 0;

#Dates for comparison
my $entered_time = str2time ($today_date);
#print "Entered time: " . $entered_time . "\n"; 
my $minus_one_year = ($entered_time - 31536000);
my $minus_two_year = ($entered_time - 63072000);

my @array;
# Subroutine called on each file 
sub checkTime { 
  
    my @info = stat($_[0]); 
    my $filesize = stat($_[0])->size;
    $sizeArray[$length] = $filesize;
    $length++;
    #print -s @info . "\n";
    my $filetime = Date::EzDate->new($info[8]);
    my $access_time = (stat $_[0])->mtime;
    #print "Access time: " . $access_time . "\n";
    if ($compare_time > $filetime) { 
      
        #print getcwd() . '/' . $_[0] . "\n"; 
	my $file = ($_[0]);
	#print "File: " . $file . "\n";
	#print -s $file . "\n";
	if ($access_time > ($minus_one_year)) {
		#print "Less Than One Year Old" . "\n";
		$less_one_count++;
	}
	elsif ($access_time <= ($minus_one_year) && $access_time > ($minus_two_year)) {
		#print "Between One and Two Years Old" . "\n";
		$between_one_two_count++;	
	}
	else {
	#print "Two Or More Years Old" . "\n";
	$over_two_count++; 
	}
	@array[$totalfilecount] = $file =~ /(\.[^.]+)$/;   
    } 
    
    #print $length . "\n";
    
    $totalfilecount++;
    
    return File::DirWalk::SUCCESS; 
      
} 
  
# Start the process! 
$dir->walk($ARGV[0]);

#Checks file size array, tallies files that
#meet certain size criteria
foreach(@sizeArray) {
	if ( $_ < 1048576) {
		$mbcounter++;
	}
	if ( $_ > 1048576 && $_ < 5242880) {
		$mbcounter2++;
	}
	if ( $_ > 5242880 && $_ < 26214400) {
		$mbcounter3++;
	} 
	if ( $_ > 26214400  && $_ < 1073741824) {
		$mbcounter4++;
	}
	if ( $_ > 1073741824) {
		$mbcounter5++;
	}
}

#Performs sort to find min/max file sizes
my $max = (sort{$b <=> $a} @sizeArray)[0];
my $min = (sort{$a <=> $b} @sizeArray)[0];

#Output to file
my $outputfile = 'data.txt';
open (my $FILE, '>', $outputfile);
print $FILE "###########FILE STATISTICS#########################" . "\n";
print $FILE "Max file size is: " . $max . " bytes\n";
print $FILE "Min file size is: " . $min . " bytes\n";
print $FILE "Avg. file size is: " . sum(@sizeArray)/@sizeArray . " bytes\n";
print $FILE "Less than 1MB: " . $mbcounter . "\n";
print $FILE "Between 1MB and 5MB: " . $mbcounter2 . "\n";
print $FILE "Between 5MB and 25MB: " . $mbcounter3 . "\n";
print $FILE "Between 25MB and 1GB: " . $mbcounter4 . "\n";
print $FILE "Over 1GB: " . $mbcounter5 . "\n";
print $FILE "Total number of files: " . $totalfilecount . "\n";
print $FILE "Files modified less than one year: " . $less_one_count . "\n";
print $FILE "Files modified between one and two years: " . $between_one_two_count . "\n";
print $FILE "Files modified two or more years: " . $over_two_count . "\n";

#Counts Appearance of Each File Extension
my @words = @array;
my $key = 0;
my $value = 0;
my %count = ();
%count = ();
foreach my $line (@words)
    {
       
        chomp($line);       
        my @parts = split( /\s+/, $line );  
        foreach my $hash_var (@parts) 
            {
                $count{$hash_var}++;
            }
    }
  while ( ($key,$value) = each %count ) 
    {
        print $FILE "File Extension <", "$key" , ">", " appeared " , "$value" , " time(s)\n";
    }

close ($FILE);
