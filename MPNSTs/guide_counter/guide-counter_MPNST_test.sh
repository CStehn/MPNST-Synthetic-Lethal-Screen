cd /home/largaesp/stehn007/synthetic_lethal

module load conda
source activate mageckenv

# only the MPNSTs were sequenced together
# thus, use the MPNST lines as normalization controls
# make smaller guide-counter table to use in test module
awk '{print $1"\t"$2"\t"$12"\t"$13"\t"$14"\t"$15}' synthetic_lethal_ALL.counts.txt > guide-counter.MPNSTs.txt

mageck test \
	-k guide-counter.MPNSTs.txt \
	-t STS26T.F \
	-c STS26T.I \
	-n STS26T \
	--norm-method median


