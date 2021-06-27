#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;

# argument processing
my $audit=0;
my $votingdevice=0;
my $votingserver=0;
my $registrar=0;
my $votingsheet=0;
my $password=0;
my $tofile=0;

sub conv {
    my ($o,$s)=@_;
    if ($s eq '0' || $s eq 'honest' || (($o eq 'votingsheet' || $o eq 'password') && $s eq 'secret')) {return 0;}
    if ($s eq '1' || $s eq 'dishonest' || (($o eq 'votingsheet' || $o eq 'password') && $s eq 'lost')) {return 1;}
    if ($o eq 'audit' && ($s eq '2' || $s eq 'none')) {return 2;}
    die "bad option $o: $s, stopped";
}

GetOptions ('audit|a=s' => sub {$audit=conv(@_);},
            'votingdevice|d=s' => sub {$votingdevice=conv(@_);},
            'votingserver|s=s' => sub {$votingserver=conv(@_);},
            'registrar|r=s' => sub {$registrar=conv(@_);},
            'votingsheet|vs=s' => sub {$votingsheet=conv(@_);},
            'password|p=s' => sub {$password=conv(@_)},
            'file|f' => \$tofile)
    or die;

sub readfile {
    my ($file) = @_;
    open(my $in,"<:encoding(UTF-8)",$file) or die "Error when opening file $file: $!";
    local $/=undef;
    my $r = <$in>;
    close($in);
    return $r;
}

sub writefile {
    my ($file,$s) = @_;
    open(my $out,">:encoding(UTF-8)",$file) or die "Error when opening file $file: $!";
    print $out $s;
    close($out);
    return;
}

    
# instantiating with the correct trust assumption

sub instantiate {
    $_ = $_[0];
    #audit
    if ($audit==0) {
        s/#IFAUDIT(.*?)#ENDIF/$1/gs;
        s/#IFHAUDIT(.*?)#ENDIF/$1/gs;
        s/#IFNOAUDIT(.*?)#ENDIF//gs;
        s/#IFDAUDIT(.*?)#ENDIF//gs;
    }
    if ($audit==1) {
        s/#IFAUDIT(.*?)#ENDIF/$1/gs;
        s/#IFHAUDIT(.*?)#ENDIF//gs;
        s/#IFNOAUDIT(.*?)#ENDIF//gs;
        s/#IFDAUDIT(.*?)#ENDIF/$1/gs;
    }
    if ($audit==2) {
        s/#IFAUDIT(.*?)#ENDIF//gs;
        s/#IFHAUDIT(.*?)#ENDIF//gs;
        s/#IFNOAUDIT(.*?)#ENDIF/$1/gs;
        s/#IFDAUDIT(.*?)#ENDIF//gs;
    }

    #registrar
    if ($registrar==0) {
        s/#IFHREGISTRAR(.*?)#ENDIF/$1/gs;
        s/#IFDREGISTRAR(.*?)#ENDIF//gs;
    } else {
        s/#IFHREGISTRAR(.*?)#ENDIF//gs;
        s/#IFDREGISTRAR(.*?)#ENDIF/$1/gs;
    }
    
    #voting device
    if ($votingdevice==0) {
        s/#IFHVOTINGDEVICE(.*?)#ENDIF/$1/gs;
        s/#IFDVOTINGDEVICE(.*?)#ENDIF//gs;
    } else {
        s/#IFHVOTINGDEVICE(.*?)#ENDIF//gs;
        s/#IFDVOTINGDEVICE(.*?)#ENDIF/$1/gs;
        s/#IFDVOTERCHAN(.*?)#ENDIF/$1/gs;
    }

    #voting server
    if ($votingserver==0) {
        s/#IFHVOTINGSERVER(.*?)#ENDIF/$1/gs;
        s/#IFDVOTINGSERVER(.*?)#ENDIF//gs;
    } else {
        s/#IFHVOTINGSERVER(.*?)#ENDIF//gs;
        s/#IFDVOTINGSERVER(.*?)#ENDIF/$1/gs;
        s/#IFDVOTERCHAN(.*?)#ENDIF/$1/gs;
    }

    #password
    if ($password==1) {
        s/#IFLOSEPASSWORD(.*?)#ENDIF/$1/gs;
        s/#IFDVOTERCHAN(.*?)#ENDIF/$1/gs;
    } else {
        s/#IFLOSEPASSWORD(.*?)#ENDIF//gs;
        s/#IFDVOTERCHAN(.*?)#ENDIF//gs;
    }
    
    #voting sheet
    if ($votingsheet==1) {
        s/#IFLOSEVS(.*?)#ENDIF/$1/gs;
    } else {
        s/#IFLOSEVS(.*?)#ENDIF//gs;
    }
    return $_;
}

# reading the voter first (no need to read it twice)
my $honestvoter = readfile("honest-voter.pv");

# reading all the files
my $all = "";
$all .= readfile("setup.pv");
$all .= readfile("honest-registrar.pv");
$all .= $honestvoter =~ s/\$vote/a/gr =~ s/\$VOTE/A/gr =~ s/#IFLOSEVS(.*?)#ENDIF/$1/gsr =~ s/#IFLOSEPASSWORD(.*?)#ENDIF//gsr =~ s/#IFAUDIT(.*?)#ENDIF/$1/gsr =~ s/#IFHAUDIT(.*?)#ENDIF//gsr =~ s/#IFNOAUDIT(.*?)#ENDIF//gsr =~ s/#IFDAUDIT(.*?)#ENDIF/$1/gsr;
$all .= $honestvoter =~ s/\$vote/b/gr =~ s/\$VOTE/B/gr =~ s/#IFLOSEVS(.*?)#ENDIF/$1/gsr =~ s/#IFLOSEPASSWORD(.*?)#ENDIF//gsr =~ s/#IFAUDIT(.*?)#ENDIF/$1/gsr =~ s/#IFHAUDIT(.*?)#ENDIF//gsr =~ s/#IFNOAUDIT(.*?)#ENDIF//gsr =~ s/#IFDAUDIT(.*?)#ENDIF/$1/gsr;
$all .= $honestvoter =~ s/\$vote/a/gr =~ s/\$VOTE/A/gr =~ s/#IFLOSEVS(.*?)#ENDIF//gsr =~ s/#IFLOSEPASSWORD(.*?)#ENDIF/$1/gsr =~ s/#IFDVOTERCHAN(.*?)#ENDIF/$1/gsr;
$all .= $honestvoter =~ s/\$vote/b/gr =~ s/\$VOTE/B/gr =~ s/#IFLOSEVS(.*?)#ENDIF//gsr =~ s/#IFLOSEPASSWORD(.*?)#ENDIF/$1/gsr =~ s/#IFDVOTERCHAN(.*?)#ENDIF/$1/gsr;
$all .= readfile("dishonest-voter.pv");
#$all .= readfile("honest-audit.pv");
$all .= readfile("honest-votingdevice.pv");
$all .= readfile("honest-votingserver.pv");
$all .= readfile("dishonest-votingserver.pv");
$all .= readfile("security-properties.pv");
$all .= readfile("main-both.pv");

my $fileout="generated-files/both-r".$registrar." a".$audit." d".$votingdevice." s".$votingserver." vs".$votingsheet." pwd".$password.".pv";

if ($tofile==0) {
    print instantiate($all);
} else {
    writefile($fileout, instantiate($all));
    print $fileout;
}
