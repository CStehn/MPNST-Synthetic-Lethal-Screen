module load conda
source activate guide-counter

bg="/home/largaesp/stehn007/synthetic_lethal"
cd $bg

find "/home/largaesp/data_delivery/umgc/2022-q4/221003_A00223_0932_AHHTCNDRX2/Largaespada_Project_148/" -type f -name "*R1_001.fastq.gz" > screen_files.txt

find "/home/largaesp/data_delivery/umgc/2023-q1/230123_A00223_0995_AHWNCTDRX2/Largaespada_Project_149/" -type f -name "*R1_001.fastq.gz" >> screen_files.txt 

fastq=$(cat screen_files.txt)
rm screen_files.txt

guide-counter count \
	--input	$fastq \
	--control-guides ${bg}/broadgpp-brunello-controls.txt \
	--library ${bg}/broadgpp-brunello-library-corrected.txt \
	--samples ipn3D.M ipn2J.M ipn1L.I ipn1L.F ipn1L.M ipn2J.I ipn2J.F ipn3D.I ipn3D.F ST88-14.F ST88-14.I STS26T.I STS26T.F \
	--output synthetic_lethal_ALL

conda deactivate
