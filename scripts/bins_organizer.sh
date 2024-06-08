# Script para organizar los resultados de magcheck en sus respectivas carpetas
# Uso: bash bins_organizer.sh

cat /home/mariel/Camda2024Microbioma/data/mismuestras.txt | while read line
do
mv ~/Camda2024Microbioma/mags/${line}* ~/Camda2024Microbioma/mags/${line}/
done
