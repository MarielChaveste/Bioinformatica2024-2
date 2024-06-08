# Script para crear los links simbólicos a las muestras
# Uso: bash symboliclink.sh

cat /home/mariel/Camda2024Microbioma/data/mismuestras.txt | while read line
do
ln -s /files/camda2024/gut/scripts/${line}_1.* ~/Camda2024Microbioma/reads/
ln -s /files/camda2024/gut/scripts/${line}_2.* ~/Camda2024Microbioma/reads/
done