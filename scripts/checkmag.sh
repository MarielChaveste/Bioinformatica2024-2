# Script para checar la calidad de los mags
# Uso: bash checkmag.sh

cat /home/mariel/Camda2024Microbioma/data/mismuestras.txt | while read line
do
checkm taxonomy_wf domain Bacteria -x fasta /Camda2024Microbioma/mags/${line}/ /Camda2024Microbioma/mags/${line}/CHECKM/
#checkm qa /Camda2024Microbioma/mags/${line}/CHECKM/Bacteria.ms CHECKM/ --file /Camda2024Microbioma/mags/${line}/CHECKM/quality_${line}.tsv --tab_table -o 2
done
