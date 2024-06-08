# Script para realizar el filtrado y limpieza de las muestras pareadas
# Uso: bash trimmingsamples.sh

for infile in *_1.fastq.gz
do
  echo "Limpiando la muestra ${infile%_1.fastq.gz}"
  trimmomatic PE ${infile} ${infile%_1.fastq.gz}_2.fastq.gz \
  ${infile%_1.fastq.gz}_1.trim.fastq.gz ${infile%_1.fastq.gz}_1un.trim.fastq.gz \
  ${infile%_1.fastq.gz}_2.trim.fastq.gz ${infile%_1.fastq.gz}_2un.trim.fastq.gz \
  SLIDINGWINDOW:4:20 MINLEN:35 ILLUMINACLIP:TruSeq3-PE.fa:2:40:15
done