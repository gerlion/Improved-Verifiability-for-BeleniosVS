#!/usr/bin/env bash

# all cases regarding the corruption of the various entities
for reg in honest dishonest;
do
    for aud in honest dishonest none;
    do
        for vdev in honest dishonest;
        do
            for vser in honest dishonest;
            do
                for vs in secret lost;
                do
                    for pwd in secret lost;
                    do
                        FILE="$(perl gen.pl --file --registrar $reg --audit $aud --votingdevice $vdev --votingserver $vser --votingsheet $vs --password $pwd)";
                        RES="$(proverif "$FILE" | perl scan.pl --registrar $reg --votingserver $vser)";
                        #echo "registrar $reg, audit $aud, votingdevice $vdev, votingserver $vser, votingsheet $vs, password $pwd: $RES";
                        echo "$RES";
                    done;
                done;
            done;
        done;
    done;
done;


# all authorities honest, some voters lose their voting sheet and others lose their password
#FILE="$(perl gen-both.pl --file)";
#RES="$(proverif "$FILE" | perl scan.pl --registrar honest --votingserver honest)";
#echo "all authorities honest, some voters lose their voting sheet and others lose their password: $RES";
