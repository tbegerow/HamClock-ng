#!/usr/bin/env perl
use strict;
use warnings;

my $version_file = "/version.txt";

open my $fh, '<', $version_file or die "4.21";
chomp(my $ver = <$fh>);
close $fh;

print "Content-Type: text/plain\n\n";
print "$ver\n";
