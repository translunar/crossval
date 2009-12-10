#!/usr/bin/perl -w
use strict;
use warnings;

# Just a stupid script--goes through the files in a list of directories and sorts by
# the third column in descending order.
# First argument is the destination directory.
# Note that this version sorts on the second column as opposed to the third. In other words, it doesn't look for a known column.

# Get destination dir or offer the user instructions.
my $destdir = $ARGV[0]
  or die("\nFormat:\n\n\t./sortall.pl destination source1 source2 ... sourceN\n\nMust have at least a destination directory; one or more source directories are required.\n\n");

# Simple check.
for my $i (1 .. scalar(@ARGV)-1) {
  # print STDOUT "$i\t$ARGV[$i]\t$destdir\n";
  if ($destdir eq $ARGV[$i]) {
    die("Destination directory cannot be the same as a source directory.\n");
  }
}

# Does the destination directory exist?
if (-d $destdir) {
  # Make sure directory is empty.
  opendir(DIR, $destdir) or die "$!";
  readdir DIR; # ignore .
  readdir DIR; # ignore ..
  if (readdir DIR) {
    die("Directory '$destdir' is not empty.");
  }
  close DIR;
} else {
  print STDOUT "Creating directory '$destdir'\n";
  `mkdir $destdir`;
}

print STDOUT "Sorting to directory '$destdir'\n";

# hash key is a filename; values are a string of dir/filename, space-separated
my %file = ();

my $count = 0;
foreach my $dir (@ARGV) {
  if ($count == 0) { # Skip destination directory
    $count++;
    next;
  }
  
  print "Acquiring filenames from $dir...\n";  
  # Read directory contents
  my @files = [];
  opendir(DIR, "./$dir") or die "Can't open directory '$dir'!";
  @files = grep(!/^\.\.?$/, readdir(DIR));
  closedir(DIR);
  
  foreach my $f (@files) {
  
    # Write headers first
    unless (-e "$destdir/$f") {
      `head -n 2 $dir/$f > $destdir/$f`;
    }
    
    # If file exists in this dir, add path to hash
    if (-e "$dir/$f") {
      $file{$f} .= " $dir/$f";
    }
  }
  
  $count++;
}

print "Acquired filenames. Now sorting into $destdir...\n";

foreach my $f (keys(%file)) {
  # Now sort all but the headers onto the end of the output file
  `tail -q -n+3 $file{$f} |sort -grk 2 >> $destdir/$f`;
}


