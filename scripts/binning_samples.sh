# Script para obtener los bins de las muestras
# Uso: bash binning_samples.sh
cat /home/mariel/Camda2024Microbioma/data/mismuestras.txt | while read line
do
run_MaxBin.pl -thread 20 -contig  /home/mariel/Camda2024Microbioma/assembled/assembled_${line}/final.contigs.fa \
-reads  /home/mariel/Camda2024Microbioma/trimmedReads/${line}_1.trim.fastq.gz \
-reads2 /home/mariel/Camda2024Microbioma/trimmedReads/${line}_2.trim.fastq.gz \
-out /home/mariel/Camda2024Microbioma/mags/${line}
done

