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
use File::Find::Rule;
use Cwd qw(getcwd);
use SLURM qw(send2slurm);
use File::Basename qw(basename);
use Data::Dump qw(dump);
my $odir;
my $ilist;

@ARGV = ("-h") unless @ARGV;
while (@ARGV and $ARGV[0] =~ /^-/) {
	$_ = shift;
	last if /^--$/;
	if (/^-o/) {$odir = shift; chomp $odir;}
	if (/^-i/) {$ilist = shift; chomp $ilist;}
}

die "Should supply output directory\n" unless $odir;
die "Should supply file list\n" unless $ilist;

my @gmluts = (3, 10, 11, 12, 13, 17, 18, 26, 42, 49, 50, 51, 52, 53, 54, 58);
my @wmluts = (2, 16, 28, 41, 60, 77, 85, 251, 252, 253, 254, 255);
my %subjects;
my $cwdir = getcwd();
my $wdir = $cwdir.'/working';
unless (-d $wdir) {mkdir $wdir;}
open IDF, "<$ilist" or die "Could not open file\n";
while (<IDF>) {
	my ($sid, $fsid) = /(.*),(.*)/;
	$subjects{$sid} = $fsid;
	my $tdir = tempdir( CLEANUP => 1);
	my $order = $ENV{'PIPEDIR'}.'/bin/get_fsaseg.sh '.$fsid.' '.$sid.' '.$tdir;
	system($order);
	my $imlist = $ENV{'FSLDIR'}.'/bin/fslmaths ';
	my $first = 1;
	foreach my $roi (@gmluts){
		$imlist .= ($first?' ':' -add ').$tdir.'/'.$sid.'_'.$roi.'.nii.gz';
		$first = 0;
		$order = $ENV{'PIPEDIR'}.'/bin/get_lut.sh '.$sid.' '.$tdir.' '.$roi;
		system($order);
	}
	$order = $imlist.' '.$wdir.'/'.$sid.'_GM.nii.gz';
	print "$order\n";
	system($order);
        $imlist = $ENV{'FSLDIR'}.'/bin/fslmaths ';
	$first = 1;
        foreach my $roi (@wmluts){
                $imlist .= ($first?' ':' -add ').$tdir.'/'.$sid.'_'.$roi.'.nii.gz';
		$first = 0;
                $order = $ENV{'PIPEDIR'}.'/bin/get_lut.sh '.$sid.' '.$tdir.' '.$roi;
                system($order);
        }
        $order = $imlist.' '.$wdir.'/'.$sid.'_WM.nii.gz';
	system($order);
}
close IDF;
my $tmp = tempdir( CLEANUP => 1);
my @twm; my @tgm;
my $seg_file = 'seg_files.csv';
my $flist = $wdir.'/'.$seg_file;
open TPF,">$flist" or die "$!\n";
foreach my $sid (sort keys %subjects){
	my $order = $ENV{'ANTS_PATH'}.'/antsRegistrationSyNQuick.sh -d 3 -f '.$ENV{'FSLDIR'}.'/data/standard/MNI152_T1_2mm.nii.gz -m '.$wdir.'/'.$sid.'_GM.nii.gz -t a -o '.$tmp.'/'.$sid.'_GM_init_';
	system($order);
	$order = $ENV{'ANTS_PATH'}.'/antsApplyTransforms -d 3 -r '.$ENV{'FSLDIR'}.'/data/standard/MNI152_T1_2mm.nii.gz -i '.$wdir.'/'.$sid.'_GM.nii.gz -t '.$tmp.'/'.$sid.'_GM_init_0GenericAffine.mat -o '.$tmp.'/'.$sid.'_GM0.nii.gz';
	system($order);
	push @tgm, $tmp.'/'.$sid.'_GM0.nii.gz';
        $order = $ENV{'ANTS_PATH'}.'/antsRegistrationSyNQuick.sh -d 3 -f '.$ENV{'FSLDIR'}.'/data/standard/MNI152_T1_2mm.nii.gz -m '.$wdir.'/'.$sid.'_WM.nii.gz -t a -o '.$tmp.'/'.$sid.'_WM_init_';
        system($order);
        $order = $ENV{'ANTS_PATH'}.'/antsApplyTransforms -d 3 -r '.$ENV{'FSLDIR'}.'/data/standard/MNI152_T1_2mm.nii.gz -i '.$wdir.'/'.$sid.'_WM.nii.gz -t '.$tmp.'/'.$sid.'_WM_init_0GenericAffine.mat -o '.$tmp.'/'.$sid.'_WM0.nii.gz';
        system($order);
	push @twm, $tmp.'/'.$sid.'_WM0.nii.gz';
	print TPF $wdir.'/'.$sid.'_GM.nii.gz,'.$wdir.'/'.$sid.'_WM.nii.gz'."\n";
}
close TPF;
my $aux = join ' ',@tgm;
my $order = $ENV{'FSLDIR'}.'/bin/fslmerge -t '.$tmp.'/GM0template.nii.gz '.$aux;
system($order);
$order = $ENV{'FSLDIR'}.'/bin/fslmaths '.$tmp.'/GM0template.nii.gz '.$tmp.'/avg_GM.nii.gz';
system($order);
$aux = join ' ',@twm;
$order = $ENV{'FSLDIR'}.'/bin/fslmerge -t '.$tmp.'/WM0template.nii.gz '.$aux;
system($order);
$order = $ENV{'FSLDIR'}.'/bin/fslmaths '.$tmp.'/WM0template.nii.gz '.$tmp.'/avg_WM.nii.gz';
system($order);
$order = 'cd '.$wdir.';'.$ENV{'ANTS_PATH'}.'/antsMultivariateTemplateConstruction2.sh -d 3 -a 0 -b 0 -c 5 -u 1:0:0 -e 1 -g 0.25 -i 4 -k 2 -w 1x1 -q 70x50x30x10 -f 6x4x2x1 -s 3x2x1x0 -n 0 -o antsTPL_ -r 0 -l 1 -m CC -t SyN -y 0 -z '.$tmp.'/avg_GM.nii.gz -z '.$tmp.'/avg_WM.nii.gz '.$seg_file;
print "$order\n";
system($order);
foreach my $sid (sort keys %subjects){
	my $order = $ENV{'ANTS_PATH'}.'/antsApplyTransforms -d 3 -i '.$wdir.'/'.$sid.'_GM.nii.gz -r '.$wdir.'/antsTPL_template0.nii.gz -o '.$wdir.'/'.$sid.'_fulltransf.nii.gz -t '.$wdir.'/antsTPL_'.$sid.'_GM*1Warp.nii.gz -t '.$wdir.'/antsTPL_'.$sid.'_GM*0GenericAffine.mat --float || true';
	print "$order\n";
	system($order);
	$order = $ENV{'ANTS_PATH'}.'/CreateJacobianDeterminantImage 3 '.$wdir.'/antsTPL_'.$sid.'_fulltransf.nii.gz '.$wdir.'/'.$sid.'_jacobian.nii.gz 0 1 || true';
	print "$order\n";
	system($order);
	$order = $ENV{'FSLDIR'}.'/bin/fslmaths '.$wdir.'/'.$sid.'_fulltransf.nii.gz -mul '.$wdir.'/'.$sid.'_jacobian.nii.gz '.$wdir.'/'.$sid.'_GM2temp_mod';
	print "$order\n";
	system($order);
}
my @regoks = find(file => 'name' => "*_fulltransf.nii.gz", in => $wdir);
my @fsums;
my $nomodsums = join ' ', @regoks;
(my $modsums = $nomodsums) =~ s/fulltransf/GM2temp_mod/g;
my $statsdir = $cwdir.'/stats';
unless (-d $statsdir) {mkdir $statsdir;}
$order = $ENV{'FSLDIR'}.'/bin/fslmerge -t '.$statsdir.'/GM_merg '.$nomodsums;
print "$order\n";
system($order);
$order = $ENV{'FSLDIR'}.'/bin/fslmerge -t '.$statsdir.'/GM_mod_merg '.$modsums;
print "$order\n";
system($order);
foreach my $regok (@regoks){
	$regok = basename $regok;
	$regok =~ s/(.*)_.*/$1/;
	print "$regok\n";
}


