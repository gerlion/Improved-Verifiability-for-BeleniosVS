#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;

# argument processing
my $votingserver=0;
my $registrar=0;

sub conv {
    my ($o,$s)=@_;
    if ($s eq '0' || $s eq 'honest') {return 0;}
    if ($s eq '1' || $s eq 'dishonest') {return 1;}
    die "bad option $o: $s, stopped";
}

GetOptions ('votingserver|s=s' => sub {$votingserver=conv(@_);},
            'registrar|r=s' => sub {$registrar=conv(@_);})
    or die;

my $cast_as_intended_id = "";
my $indverif_id = "";
my $cast_as_intended_cred = "";
my $indverif_cred = "";
my $check = "";
my $reach = "";

while (<>) {
    
    if (/RESULT not \(event\(VOTER.* (is true|is false|cannot be proved)\./) {
        $reach = $1;
    }
    
    if (/RESULT event\(VERIFIED.* ==> event\(VOTE\(.* (is true|is false|cannot be proved)\./) {
        $check = $1;
    }
    if (/RESULT event\(VERIFIED.* ==> event\(GOING_TO_TALLY.* (is true|is false|cannot be proved)\./) {        
        $indverif_id = $1;
    }
    if (/RESULT event\(VERIFIED.* ==> event\(VOTER.* (is true|is false|cannot be proved)\./) {
        $indverif_cred = $1;
    }
    if (/RESULT event\(GOING_TO_TALLY\(([^,]*),([^,]*),.* ==> .*event\(VOTER\(([^,]*),([^,]*),H.* (is true|is false|cannot be proved)\./) {        
        if ($1 eq $3) {
            $cast_as_intended_id = $5;
        }
        if ($2 eq $4) {
            $cast_as_intended_cred = $5;
        }
    }
}

if ($reach eq "" || $check eq "" || $indverif_id eq "" || $indverif_cred eq "" || $cast_as_intended_id eq "" || $cast_as_intended_cred eq "") {
    print "Check ${check}\n";
    print "indverif_id ${indverif_id}\n";
    print "indverif_cred ${indverif_cred}\n";
    print "cast_as_intended_i ${cast_as_intended_id}\n";
    print "cast_as_intended_cred ${cast_as_intended_cred}\n";
    print "unable to parse proverif output correctly.\n"
}

if ($check ne "is true") {
    die "honest voter behaviour is not proved."
}

if ($reach ne "is false") {
    die "honest voter behaviour does not terminate."
}


if (($votingserver==0 && $indverif_id eq "is true" && $cast_as_intended_id eq "is true") || ($registrar==0 && $indverif_cred eq "is true" && $cast_as_intended_cred eq "is true")) {
    print "1\n";
} else {
    if (($votingserver==0 && ($indverif_id eq "is false" || $cast_as_intended_id eq "is false")) || ($registrar==0 && ($indverif_cred eq "is false" || $cast_as_intended_cred eq "is false"))) {
        print "0\n";
    } else {
        if ($votingserver==1 && $registrar==1) {
            print "0\n";
        } else {
            print "cannot be proved.\n";
        }
    }
}
#print "check ".$check." ivid ".$indverif_id." caiid ".$cast_as_intended_id." ivcred ".$indverif_cred." caicred ".$cast_as_intended_cred."\n";
