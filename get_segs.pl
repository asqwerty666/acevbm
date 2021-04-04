#!/usr/bin/perl

# Copyright 2021 O. Sotolongo <asqwerty@gmail.com>

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

use strict; use warnings;
use File::Temp qw(tempdir);
use Cwd qw(getcwd);
my $odir;
my $ilist;

@ARGV = ("-h") unless @ARGV;
while (@ARGV and $ARGV[0] =~ /^-/) {
	$_ = shift;
	last if /^--$/;
	if (/^-o/) {$odir = shift; chomp $idir;}
	if (/^-i/) {$ilist = shift; chomp $ilist;}
}

die "Should supply output directory\n" unless $odir;
die "Should supply file list\n" unless $ilist;

my @gmluts = (3, 10, 11, 12, 13, 17, 18, 26, 42, 49, 50, 51, 52, 53, 54, 58);
my @wmluts = (2, 16, 28, 41, 60, 77, 85, 251, 252, 253, 254, 255);

open IDF, "<$ilist" or die "Could not open file\n";
while (<IDF>) {
	my ($sid, $fsid) = /(.*),(.*)/;
	my $tdir = tempdir( CLEANUP => 1);
	my $cwdir = getcwd();
	$wdir = $cwdir.'/working';
	unless (-d $wdir) {mkdir $wdir;}
	my $order = $cwdir.'/get_aseg.sh '.$fsid.' '.$sid.' '.$tdir;
	system($order);
	foreach my $roi (@gmluts){
		$order = $cwdir.'/get_lut.sh '.$sid.' '.$tdir.' '.$roi;
		system($order);
	}
}
