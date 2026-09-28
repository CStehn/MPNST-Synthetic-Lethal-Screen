#!/bin/bash
#SBATCH --ntasks=8
#SBATCH --mem=40gb
#SBATCH -t 8:00:00
#SBATCH -p agsmall
#SBATCH --mail-user=stehn007@umn.edu
#SBATCH --mail-type=ALL
#SBATCH -e chronos_calc.err
#SBATCH -o chronos_calc.out



cd /projects/standard/largaesp/shared/synthetic_lethal

module load miniforge
source activate chronos

python chronos_calc_w_achilles.py
