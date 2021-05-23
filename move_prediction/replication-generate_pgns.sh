#!/bin/bash

set -e

#Read the raw pgns from lichess and filter out the elo ranges we care about

mkdir -p ../data/pgns_ranged_filtered/
for i in {1900..2000..100}; do
    echo $i
    upperval=$(($i + 100))
    outputdir="../data/pgns_ranged_filtered/${i}"
    mkdir -p $outputdir
    for f in ../data/lichess_raw/lichess_db_standard_rated_2017* ../data/lichess_raw/lichess_db_standard_rated_2018* ../data/lichess_raw/lichess_db_standard_rated_2019-{01..11}.pgn.bz2; do
        fname="$(basename -- $f)"
        echo "${i}-${fname}"
        #screen -S "${i}-${fname}" -dm bash -c "source ~/.bashrc; python3 ../data_generators/extractELOrange.py --remove_bullet --remove_low_time ${i} ${upperval} ${outputdir}/${fname} ${f}"
        python3 replication-extractELOrange.py --remove_bullet --remove_low_time ${i} ${upperval} ${outputdir}/${fname} ${f} &
    done
done

# Wait for donzo
wait

# You have to wait for the screens to finish to do this
# We use pgn-extract to normalize the games and prepare for preprocessing
# This also creates blocks of 200,000 games which are useful for the next step

mkdir -p ../data/pgns_ranged_blocks
for i in {1900..2000..100}; do
    echo $i
    cw=`pwd`
    outputdir="../data/pgns_ranged_blocks/${i}"
    mkdir -p $outputdir
    cd $outputdir
    for y in {2017..2019}; do
        echo "${i}-${y}"
        mkdir -p $y
        cd $y
        # screen -S "${i}-${y}" -dm bash -c "source ~/.bashrc; bzcat \"../../../pgns_ranged_filtered/${i}/lichess_db_standard_rated_${y}\"* | pgn-extract -7 -C -N  -#200000"
        bzcat \"../../../pgns_ranged_filtered/${i}/lichess_db_standard_rated_${y}\"* | pgn-extract -7 -C -N  -#200000 &
        cd ..
    done
    cd $cw
done

# wait for donzo (again)
wait

#Now we have all the pgns in blocks we can randomly sample and creat testing and training sets of 60 and 3 blocks respectively
python3 replication-move_training_set.py
