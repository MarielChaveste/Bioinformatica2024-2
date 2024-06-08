# Script para obtener la asignación taxonómica a partir de los reads
# Uso: bash tax_kraken2.sh

cat /home/mariel/Camda2024Microbioma/data/mismuestras.txt | while read line
do
kraken2 --db /files/db_kraken2 --threads 20 --paired ~/Camda2024Microbioma/trimmedReads/${line}_1.trim.fastq.gz ~/Camda2024Microbioma/trimmedReads/${line}_2.trim.fastq.gz \
--output ~/Camda2024Microbioma/taxonomy_reads/${line}/${line}.kraken \
--report ~/Camda2024Microbioma/taxonomy_reads/reports/${line}.report
done
