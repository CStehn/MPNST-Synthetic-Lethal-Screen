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
#SBATCH -e MAGeCK_mle_MPNST.err
#SBATCH -o MAGeCK_mle_MPNST.out

module load conda
source activate mageckenv

HOME="/home/largaesp/stehn007"
CRISPR="${HOME}/synthetic_lethal"
COUNTS="${CRISPR}/MPNSTs/counts"
OUT="${CRISPR}/MPNSTs/essentiality"

cd $OUT

mageck mle \
	-k "${COUNTS}/MPNST.count.txt" \
	-d "${COUNTS}/MPNST_design.txt" \
	-n MPNST_mle
