#!/bin/bash
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -c 12
#SBATCH --mem=60gb
#SBATCH -t 12:00:00
#SBATCH -p small,amdsmall
#SBATCH -A largaesp
#SBATCH --mail-user=stehn007@umn.edu
#SBATCH --mail-type=ALL
#SBATCH -e MAGeCK_mle_%j.err
#SBATCH -o MAGeCK_mle_%j.out

module load conda
source activate mageckenv

HOME="/home/largaesp/stehn007"
CRISPR="${HOME}/synthetic_lethal"
COUNTS="${CRISPR}/counts"
OUT="${CRISPR}/essentiality"

cd $CRISPR

mkdir $OUT

mageck mle \
	-k "${COUNTS}/synthetic_lethal.count.txt" \
	-d "${CRISPR}/syn_lethal_design.txt" \
	-n synthetic_lethal
