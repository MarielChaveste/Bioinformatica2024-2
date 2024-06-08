# Script para crear un directorio para cada muestra
# Uso: bash directory_maker.sh

cat /home/mariel/Camda2024Microbioma/data/mismuestras.txt | while read line
do
mkdir ~/Camda2024Microbioma/mags/${line}/CHECKM
done

