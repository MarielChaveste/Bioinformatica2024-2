# Script para correr metaspades sobre las muestras dadas
# Uso: bash samples_assembler.sh

cat /home/mariel/Camda2024Microbioma/data/mismuestras.txt | while read line
do 
megahit -1 /home/mariel/Camda2024Microbioma/trimmedReads/${line}_1.trim.fastq.gz -2 /home/mariel/Camda2024Microbioma/trimmedReads/${line}_2.trim.fastq.gz -t 20 -o /home/mariel/Camda2024Microbioma/assembled/assembled_${line}
done
