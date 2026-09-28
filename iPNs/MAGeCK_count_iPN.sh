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
#SBATCH -e MAGeCK_count_%j.err
#SBATCH -o MAGeCK_count_%j.out

module load conda
source activate mageckenv

HOME="/home/largaesp/stehn007"
CRISPR="${HOME}/synthetic_lethal"
FASTQ="${CRISPR}/fastq"
OUT="${CRISPR}/counts"

cd $CRISPR

mkdir $OUT

# Currently not using 2nd mate reads as it can't determine trimming length
# Need to figure out how best to run this before messing with fastq paired-end reads
mageck count \
	-l ${CRISPR}/broadgpp-brunello-library-corrected.txt \
	--fastq ${FASTQ}/*R1_001.fastq.gz \
	--control-sgrna ${CRISPR}/broadgpp-brunello-controls.txt \
	--sample-label ipn3D.middle,ipn2J.middle,ipn1L.initial,ipn1L.final,ipn1L.middle,ipn2J.initial,ipn2J.final,ipn3D.initial,ipn3D.final \
	--norm-method median \
	--pdf-report \
	--keep-tmp \
	-n synthetic_lethal
