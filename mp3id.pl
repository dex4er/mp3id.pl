#!/usr/bin/perl

# mp3id (c) 1999-2000, 2013 Piotr Roszatycki <dexter@debian.org>

# This is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2, or (at your option) any later
# version.


use strict;
use warnings;

our $VERSION = 0.5;

use Cwd;
use File::Copy;
use Getopt::Long;
use MP3::Info qw(:all);

my @files;
my %opt;

GetOptions(\%opt,
    "artist|a=s",
    "album|l=s",
    "title|t=s",
    "comment|c=s",
    "year|y=i",
    "genre|g=s",
    "tracknum|n=i",
    "input|i",
    "rename|r",
    "various|v",
    "help|h",
    "<>" => sub { push @files, $_[0] },
);

if ($opt{help}) {
    die "mp3id $VERSION (c) 1999-2000, 2013 Piotr Roszatycki <dexter\@debian.org>\n".
        "This is free software under GPL and WITHOUT ANY WARRANTY\n".
        "\n".
        "usage: mp3id [--artist|-a <str>] [--title|-t <str>] [--comment|-c <str>]\n".
        "             [--album|-l <str>] [--year|-y <num>] [--genre|-g <str>]\n".
        "             [--tracknum|-n <num>] [--input|-i] [--rename|-r] [--various|-v]\n".
        "             [--help|-h]\n".
        "\n".
        "    --artist|-a <str>   sets name of artist\n".
        "    --album|-l <str>    sets album name\n".
        "    --title|-t <str>    sets song title\n".
        "    --comment|-c <str>  sets comment\n".
        "    --year|-y <num>     sets published year (4 digits)\n".
        "    --genre|-g <str>    sets genre or show genre list if given 0\n".
        "    --tracknum|-n <num> sets track number, automatically if given 0\n".
        "    --input|-i          inputs data in interactive mode\n".
        "    --rename|-r         renames filename to\n".
        "                        ../\$artist-\$album/\$tracknum-\$artist-\$title.mp3\n".
        "    --various|-v        sets \"Various\" as artist of album for renamed filename\n".
        "    --help|-h           this help info\n".
        "\n"
};

if (defined $opt{genre} && $opt{genre} eq "0") {
    # @mp3_genres is imported
    foreach (sort @mp3_genres) {
        print $_, "\n";
    }
    exit;
}

my $cwd = cwd;

if (not @files) {
    opendir my $dh, $cwd or die "can't opendir $cwd: $!";
    @files = sort grep { /\.mp3$/i and -f "$cwd/$_" } readdir $dh;
    closedir $dh;
}

my $tracknum = 0;

foreach my $file (@files) {

    my $info = get_mp3info($file) or next;
    my $tag = get_mp3tag($file);

    $tracknum ++;

    $tag->{ARTIST}   = sprintf "%.30s", $opt{artist}         if defined $opt{artist};
    $tag->{ALBUM}    = sprintf "%.30s", $opt{album}          if defined $opt{album};
    $tag->{TITLE}    = sprintf "%.30s", $opt{title}          if defined $opt{title};
    $tag->{COMMENT}  = sprintf "%.28s", $opt{comment}        if defined $opt{comment};
    $tag->{YEAR}     = sprintf "%04i",  $opt{year} % 1e4     if defined $opt{year};
    $tag->{GENRE}    = sprintf "%.30s", $opt{genre}          if defined $opt{genre};
    $tag->{TRACKNUM} = sprintf "%02i",  $opt{tracknum} % 1e2 if defined $opt{tracknum};
    $tag->{TRACKNUM} = sprintf "%02i",  $tracknum            if defined $opt{tracknum} &&
        $opt{tracknum} == 99;

    print "Filename: ", $file, "\n";

    if ($opt{input}) {
        print "Artist [",   $tag->{ARTIST},   "]: ";
        $_ = <STDIN>;
        if( chomp $_ ) {
            $_ ne '' and $tag->{ARTIST} = sprintf "%.30s", $_;
        }
        else {
            print "\n";
            delete $tag->{ARTIST};
        }
        print "Album [",    $tag->{ALBUM},    "]: ";
        $_ = <STDIN>;
        if( chomp $_ ) {
            $_ ne '' and $tag->{ALBUM} = sprintf "%.30s", $_;
        }
        else {
            print "\n";
            delete $tag->{ALBUM};
        }
        print "Title [",    $tag->{TITLE},    "]: ";
        $_ = <STDIN>;
        if( chomp $_ ) {
            $_ ne '' and $tag->{TITLE} = sprintf "%.30s", $_;
        }
        else {
            print "\n";
            delete $tag->{TITLE};
        }
        print "Comment [",  $tag->{COMMENT},  "]: ";
        $_ = <STDIN>;
        if( chomp $_ ) {
            $_ ne '' and $tag->{COMMENT} = sprintf "%.28s", $_;
        }
        else {
            print "\n";
            delete $tag->{COMMENT};
        }
        print "Year [",     $tag->{YEAR},     "]: ";
        $_ = <STDIN>;
        if( chomp $_ ) {
            $_ ne '' and $tag->{YEAR} = sprintf "%04i", $_;
        }
        else {
            print "\n";
            delete $tag->{YEAR};
        }
        print "Genre [",    $tag->{GENRE},    "]: ";
        $_ = <STDIN>;
        if( chomp $_ ) {
            $_ ne '' and $tag->{GENRE} = sprintf "%.30s", $_;
        }
        else {
            print "\n";
            delete $tag->{GENRE};
        }
        print "Tracknum [", $tag->{TRACKNUM}, "]: ";
        $_ = <STDIN>;
        if (chomp $_) {
            $_ ne '' and $tag->{TRACKNUM} = sprintf "%02i", $_;
        }
        else {
            print "\n";
            delete $tag->{TRACKNUM};
        }
    }

    if (defined $opt{artist}   || defined $opt{title} ||
        defined $opt{comment}  || defined $opt{album} ||
        defined $opt{year}     || defined $opt{genre} ||
        defined $opt{tracknum} || defined $opt{input}) {
        set_mp3tag($file, $tag);
        $tag = get_mp3tag($file);
    }

    print "A:[", $tag->{ARTIST},   "] " if $tag->{ARTIST} ne '';
    print "L:[", $tag->{ALBUM},    "] " if $tag->{ALBUM} ne '';
    print "T:[", $tag->{TITLE},    "] " if $tag->{TITLE} ne '';
    print "C:[", $tag->{COMMENT},  "] " if $tag->{COMMENT} ne '';
    print "Y:[", $tag->{YEAR},     "] " if $tag->{YEAR} ne '';
    print "G:[", $tag->{GENRE},    "] " if $tag->{GENRE} ne '';
    print "T:[", $tag->{TRACKNUM}, "] " if $tag->{TRACKNUM} ne '';
    print "\n";

    if (defined $opt{rename}) {
        my $name;
        $name = $opt{various} ? "Various" : "$tag->{ARTIST}";
        $name =~ tr/-/+/;
        $name .= "-$tag->{ALBUM}";
        $name =~ tr/ ()/_[]/;
        $name =~ s/[^a-zA-Z0-9_\[\]-]/+/g;
        my $dir = $tag->{ALBUM} ? "../$name/" : "";

        $name = "$tag->{ARTIST}";
        $name =~ tr/-/+/;
        $name .= "-$tag->{TITLE}";
        $name .= " $tag->{COMMENT}" if $tag->{COMMENT};
        $name =~ tr/ ()/_[]/;
        $name =~ s/[^a-zA-Z0-9_\[\]-]/+/g;

        $name = sprintf "%02d-$name.mp3", $tag->{TRACKNUM} ? $tag->{TRACKNUM} : $tracknum;

        my $src = $file;
        my $dst = "$dir$name";
        $dst =~ s/\//\\/g if $^O eq 'MSWin32';

        print "Rename: ", $dst, "\n";

        mkdir $dir, 0755;
        move $src, $dst;
    }

    print "\n";

}


__END__

=head1 NAME

mp3id - MP3 tag manipulate utility

=head1 SYNOPSIS

B<mp3id> S<[ B<--artist>|B<-a> I<str> ]> S<[ B<--title>|B<-t> I<str> ]>
         S<[ B<--comment>|B<-c> I<str> ]> S<[ B<--album>|B<-l> I<str> ]>
         S<[ B<--year>|B<-y> I<num> ]> S<[ B<--genre>|B<-g> I<str> ]>
         S<[ B<--tracknum>|B<-n> I<num> ]> S<[ B<--input>|B<-i> ]>
         S<[ B<--rename>|B<-r> ]> S<[ B<--various>|B<-v> ]>
         S<[ B<--help>|B<-h> ]>

=head1 DESCRIPTION

mp3id is a very simple tool written in perl with usage of MPEG::MP3Info
library. This utility allows to read tag, modify in interactive mode or
command line, and rename filename.

=head1 OPTIONS

=over 8

=item B<--artist>|B<-a> I<str>

Sets name of artist.

=item B<--album>|B<-l> I<str>

Sets album name.

=item B<--title>|B<-t> I<str>

Sets song title.

=item B<--comment>|B<-c> I<str>

Sets comment.

=item B<--year>|B<-y> I<num>

Sets published year (4 digits).

=item B<--genre>|B<-g> I<str>

Sets genre or show genre list if given 0.

=item B<--tracknum>|B<-n> I<num>

Sets track number, automatically if given 0.

=item B<--input>|B<-i>

Inputs data in interactive mode. Enter means default value. EOF (ctrl+D) means
empty value.

=item B<--rename>|B<-r>

Renames filename to ../$artist-$album/$tracknum-$artist-$title.mp3 after
modifing tag. The variables are taken from tag info.

=item B<--various>|B<-v>

Sets "Various" as artist of album for renamed filename. This is helpful
for OST or albums of various artists.

=item B<--help>|B<-h>

Show help info.

=back

=head1 AUTHOR

(c) 1999-2000, 2013 Piotr Roszatycki <dexter@debian.org>

=head1 LICENSE

All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the terms of the GNU General Public License, the latest version.
