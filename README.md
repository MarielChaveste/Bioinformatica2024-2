# Abstract

Reporte de aplicación de la metodología adquirida en el curso de Bioinformática a la etapa de preprocesamiento de datos provenientes del reto de índice de salud basado en el microbioma intestinal de la Evaluación crítica de análisis de datos masivos o CAMDA por sus siglas en inglés.
Tales métodos de preprocesamiento incluyen evaluación de calidad de las muestras con el programa fastqc, limpieza de las mismas con trimmomatic, ensamblado usando el programa MEGAHIT y clasificación taxonómica con kraken.

# Introducción

El reto CAMDA (Critical Assesstment of Massive Data Analysis) es una iniciativa internacional que busca evaluar y mejorar la capacidad de las y los investigadores para analizar conjuntos de datos masivos.
Este se basa en la realización de una serie de tareas que requieren que las y los participantes apliquen diversos métodos y herramientas para extraer información útil de grandes volúmenes de datos.
En la edición de este año 2024, se presentan los tres retos siguientes:

-   El Reto de Historias Clínicas Sintéticas o Historias Clínicas Electrónicas (HCE) altamente realistas consiste en rastrear las trayectorias de diagnóstico de pacientes diabéticos para predecir eventos clínicos relevantes de la diabetes como ceguera o cardiopatía.

-   El Reto de Predicción de Resistencia Antimicrobiana presenta secuencias de aislamientos clínicos para predecir e identificar genes/marcadores de resistencia y bacterias resistentes.

-   El Reto del Índice de Salud basado en el Microbioma Intestinal presenta cientos de perfiles taxonómicos y funcionales basados en secuencias de metagenomas completos de individuos sanos y enfermos.

El último mencionado es el reto en el cual se enfocó el equipo de trabajo del curso de bioinformática y durante este texto se dará una descripción detallada del preprocesamiento de una muestra de 100 datos.


# Materiales y métodos

Se comenzó realizando la lista de los ID's de las muestras a procesar, la cual se encuentra en la dirección `/Camda2024Microbioma/data/mismuestras.txt`. 

Posterior a ello, se crearon los links simbólicos ubicados en `/Camda2024Microbioma/data/reads` a los archivos de las muestras, las cuales se encuentran pareadas, para permitir el acceso a la información sin necesidad de duplicar información en el servidor.
El script utilizado para crear dichos links se encuentra en `~/Camda2024Microbioma/scripts/symboliclink.sh`. A continuación se puede ver el contenido del script mencionado.

```{bash link_simbolico, eval=FALSE, warning=FALSE}
# Script para crear los links simbólicos a las muestras
# Uso: bash symboliclink.sh

cat /home/mariel/Camda2024Microbioma/mismuestras.txt | while read line
do
ln -s /files/camda2024/gut/scripts/${line}_1.* ~/Camda2024Microbioma/reads/
ln -s /files/camda2024/gut/scripts/${line}_2.* ~/Camda2024Microbioma/reads/
done
```

## Calidad

Después se corrió el programa fastqc (v0.11.9) previamente instalado en el entorno metagenomics en el servidor Alnitak del Centro de Ciencias Matemáticas con el comando siguiente:

```{bash fastqc1, eval=FALSE, warning=FALSE}
fastqc *.fastq*
```

Nótese que el comando no especifica la ruta de los archivos a evaluar, debido a que este fue ejecutado en la ubicación de los links simbólicos, por otro lado se puede observar que fastqc admite múltiples archivos. Para más información sobre el uso de fastqc y el formato de archivos que admite, se puede escribir el comando siguiente en terminal:

```{bash fastqc-help, eval=FALSE, warning=FALSE}
fastqc -h
```

Una vez obtenidos los resultados generados por fastqc los cuales se almacenaron en el directorio `/Camda2024Microbioma/resultsquality1`, se realizó una exploración manual de los archivos con formato `html`, en los cuales se podrán encontrar figuras como la siguiente que es una representación de la distribución de calidades para cada posición de la secuencia de la muestra ERR209175:

```{r imagen-calidad-untrimmed, echo=FALSE, warning=FALSE}
knitr::include_graphics("~/Camda2024Microbioma/images/fastqhtml.png")
```

## Limpieza y Filtrado

En este ejemplo notamos que la muestra presenta, en aproximadamente la mitad de posiciones de la secuencia, una calidad por debajo de 24, teniendo una fracción importante de estas una calidad por debajo de 20, por lo que se decidió realizar un filtrado y limpieza de las muestras pareadas con el programa trimmomatic (v0.39) a través del script `/Camda2024Microbioma/scripts/trimmingSamples.sh`. A continuación se muestra el contenido de dicho script.

```{bash script-trimmomatic, eval=FALSE, warning=FALSE}
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
```

Una vez concluido el proceso de limpieza y filtrado, se almacenan los resultados en las carpetas `~/Camda2024Microbioma/trimmedReads` y `~/Camda2024Microbioma/untrimmedReads` (según sea el caso) y se vuelve a correr el comando

```{bash fastqc2, eval=FALSE, warning=FALSE}
fastqc *.fastq*
```

para finalmente comparar las calidades de las muestras, las cuales se almacenaron en la ruta `~/Camda2024Microbioma/trimmedReads`, por ejemplo se muestra una figura de las calidades para la muestra ERR209175 antes y después de la limpieza y filtrado, la figura siguiente muestra los resultados obtenidos con trimmomatic.

```{r imagen-calidad-trimmed, echo=FALSE, warning=FALSE}
knitr::include_graphics("~/Camda2024Microbioma/images/fastqhtmlERR209175_trimmed.png")
```

Comparando ambas figuras podemos notar el incremento en la calidad de la muestra ERR209175, más concretamente observamos que los promedios de las calidades se encuentran por encima de 26.

## Ensamble

Una vez las muestras se encuentran limpias y filtradas con calidades aceptables, procedemos a realizar el ensamble de los reads de nuestras muestras, para ello se utilizó el programa MEGAHIT (v1.2.9) instalado en el entorno de nombre `megahit` del mismo servidor a través del script ubicado en `~/Camda2024Microbioma/scripts/samples_assembler.sh` descrito a continuación:

```{bash script-megahit, eval=FALSE, warning=FALSE}
# Script para correr metaspades sobre las muestras dadas
# Uso: bash samples_assembler.sh

cat /home/mariel/Camda2024Microbioma/mismuestras.txt | while read line
do 
megahit -1 /home/mariel/Camda2024Microbioma/trimmedReads/${line}_1.trim.fastq.gz -2 /home/mariel/Camda2024Microbioma/trimmedReads/${line}_2.trim.fastq.gz -t 20 -o /home/mariel/Camda2024Microbioma/assembled/assembled_${line}
done
```

Los resultados obtenidos del script anterior fueron almacenados en un directorio para cada muestra en la ruta `~/Camda2024Microbioma/assembled`.

## Binning

Con esta información obtenida previamente, se pudieron obtener los bins, los cuales fueron almacenados en la ruta `~/Camda2024Microbioma/mags/<id_muestra>` de las muestras utilizando el programa MaxBin (v2.2.7) como se describe en el siguiente script ubicado en la ruta usual de los scripts.

```{bash script-binning, eval=FALSE, warning=FALSE}
# Script para obtener los bins de las muestras
# Uso: bash binning_samples.sh
cat /home/mariel/Camda2024Microbioma/data/mismuestras.txt | while read line
do
run_MaxBin.pl -thread 20 -contig  /home/mariel/Camda2024Microbioma/assembled/assembled_${line}/final.contigs.fa \
-reads  /home/mariel/Camda2024Microbioma/trimmedReads/${line}_1.trim.fastq.gz \
-reads2 /home/mariel/Camda2024Microbioma/trimmedReads/${line}_2.trim.fastq.gz \
-out /home/mariel/Camda2024Microbioma/mags/${line}
done
```

A partir de ello, con el programa CheckM (v1.2.1), se obtienen las tablas para visualizar de una mejor manera las calidades de los genomas ensamblados a partir de los metagenomas o MAG's por medio del script `~/Camda2024Microbioma/scripts/checkmag.sh` descrito a continuación

```{bash script-checkmag.sh, eval=FALSE, warning=FALSE}
# Script para checar la calidad de los mags
# Uso: bash checkmag.sh

cat /home/mariel/Camda2024Microbioma/data/mismuestras.txt | while read line
do
checkm taxonomy_wf domain Bacteria -x fasta /Camda2024Microbioma/mags/${line} /Camda2024Microbioma/mags/${line}/CHECKM/
checkm qa /Camda2024Microbioma/mags/${line}/CHECKM/Bacteria.ms CHECKM/ --file /Camda2024Microbioma/mags/${line}/CHECKM/quality_${line}.tsv --tab_table -o 2
done
```

## Asignación Taxonómica

Para obtener la clasificación taxonómica de cada uno de nuestros reads, requerimos utilizar el programa kraken2 (v2.1.2) con el script `~/Camda2024Microbioma/scripts/tax_kraken2.sh` descrito a continuación:

```{bash script-kraken, eval=FALSE, warning=FALSE}
# Script para obtener la asignación taxonómica a partir de los reads
# Uso: bash tax_kraken2.sh

cat /home/mariel/Camda2024Microbioma/data/mismuestras.txt | while read line
do
kraken2 --db /files/db_kraken2 --threads 6 --paired ~/Camda2024Microbioma/trimmedReads/${line}_1.trim.fastq.gz ~/Camda2024Microbioma/trimmedReads/${line}_2.trim.fastq.gz \
--output ~/Camda2024Microbioma/taxonomy_reads/${line}/${line}.kraken \
--report ~/Camda2024Microbioma/taxonomy_reads/reports/${line}/${line}.report
done
```

Como se puede ver en las líneas de código del script, los resultados se almacenaron en la dirección `~/Camda2024Microbioma/taxonomy_reads`, concretamente se utilizará la información en la ruta `~/Camda2024Microbioma/taxonomy_reads/reports/` para crear el archivo `.biom` corriendo el siguiente comando

```{bash crear-biom, eval=FALSE, warning=FALSE}
kraken-biom ~/Camda2024Microbioma/taxonomy_reads/reports/* --fmt json -o ~/Camda2024Microbioma/taxonomy_reads/tax.biom
```

como indica la línea de código, el archivo `.biom` se encuentra en la ruta `~/Camda2024Microbioma/taxonomy_reads/tax.biom`

# Resultados

# Explorando taxonomía con R

### Instalar paquetes
```{r instalar-paquetes, warning=FALSE}
#if (!requireNamespace("BiocManager", quietly = TRUE))
#  install.packages("BiocManager")

#BiocManager::install("phyloseq") # Install phyloseq


#install.packages(c("RColorBrewer", "patchwork")) 
### Install patchwork to chart publication-quality plots and readr to read rectangular datasets.
#install.packages("dplyr")
```

### Cargar paquetes
```{r llamar-paquetes, warning=FALSE}
library(BiocManager)
library("phyloseq")
library(RColorBrewer)
library(patchwork)
library(dplyr)
library(ggplot2)
```

### Fijar directorio de trabajo
```{r, warning=FALSE}
setwd("~/Camda2024Microbioma")
```

### Crear phyloseq importando los datos
Una vez importados los datos corroboramos la clase y damos un vistazo al contenido de la `tax_table`
```{r, warning=FALSE}
merged_metagenomes <- import_biom("taxonomy_reads/tax.biom")
merged_metagenomesf <- import_biom("taxonomy_reads/taxf.biom")
class(merged_metagenomes)
head(merged_metagenomes@tax_table@.Data)
```

### Modificar archivo tax.biom
Cambiamos algunos detalles de las etiquetas y columnas de la `tax_table`
```{r, warning=FALSE}
merged_metagenomes@tax_table@.Data <- substring(merged_metagenomes@tax_table@.Data, 4)

colnames(merged_metagenomes@tax_table@.Data)<- c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species")
head(merged_metagenomes@tax_table@.Data)

#f
merged_metagenomesf@tax_table@.Data <- substring(merged_metagenomesf@tax_table@.Data, 4)
colnames(merged_metagenomesf@tax_table@.Data)<- c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species")
```

### Explorar phylum

Phylum seleccionado 'Thaumarchaeota'
```{r, warning=FALSE}
unique(merged_metagenomes@tax_table@.Data[,"Phylum"])
sum(merged_metagenomes@tax_table@.Data[,"Phylum"] == "Thaumarchaeota")
#View(merged_metagenomes@otu_table@.Data)
```

### Explorando datos con algunos ejemplos de niveles taxonómicos

#### Ejemplo 1.

Phylum seleccionado "Uroviricota"
```{r, warning=FALSE}
sum(merged_metagenomes@tax_table@.Data[,"Phylum"] == "Uroviricota")
unique(merged_metagenomes@tax_table@.Data[merged_metagenomes@tax_table@.Data[,"Phylum"] == "Uroviricota", "Genus"])
#View(merged_metagenomes@otu_table@.Data)
#View(merged_metagenomes@tax_table@.Data)
```


### Graficar la alpha diversidad

Para ello primero seleccionamos únicamente las bacterias

```{r, warning=FALSE, include=FALSE}
merged_metagenomes <- subset_taxa(merged_metagenomes, Kingdom == "Bacteria")
#View(merged_metagenomes)
sample_sums(merged_metagenomes)
summary(merged_metagenomes@otu_table@.Data)
#merged_metagenomes

# f
merged_metagenomesf <- subset_taxa(merged_metagenomesf, Kingdom == "Bacteria")
```

### Alpha diversidad 
Se crea la grafica de alpha diversidad con las medidas Observed, Chao1 y Shannon

```{r, warning=FALSE}
plot_richness(physeq = merged_metagenomes, 
              measures = c("Observed","Chao1","Shannon")) 
```



```{r, warning=FALSE}
plot_richness(physeq = merged_metagenomes,
              title = "Medidas de alpha diversidad", nrow  = 2, measures = c("Observed","Chao1","Shannon"), 
              sortby = "Shannon") 
```

```{r, warning=FALSE}
summary(merged_metagenomes@tax_table@.Data== "")
```

```{r, warning=FALSE, include=FALSE}
#merged_metagenomes <- subset_taxa(merged_metagenomes, Genus != "")
#merged_metagenomes
```

```{r, warning=FALSE, include=FALSE}
#head(merged_metagenomes@otu_table@.Data)
```

```{r, warning=FALSE}
percentages <- transform_sample_counts(merged_metagenomes, function(x) x*100 / sum(x) )
head(percentages@otu_table@.Data)

# f
percentagesf <- transform_sample_counts(merged_metagenomesf, function(x) x*100 / sum(x) )
```


```{r, warning=FALSE, include=FALSE}
## Beta diversidad
#meta_ord <- ordinate(physeq = percentages, method = "NMDS", distance = "bray")
#plot_ordination(physeq = percentages, ordination = meta_ord)

# f
meta_ord <- ordinate(physeq = percentagesf, method = "NMDS", 
                     distance = "bray")

plot_ordination(physeq = percentagesf, ordination = meta_ord)
```

```{r, warning=FALSE, include=FALSE}
percentages_glom <- tax_glom(percentagesf, taxrank = 'Phylum')
```

```{r, warning=FALSE, include=FALSE}
percentages_df <- psmelt(percentages_glom)
str(percentages_df)
```

```{r, warning=FALSE, include=FALSE}
absolute_glom <- tax_glom(physeq = merged_metagenomes, taxrank = "Phylum")
absolute_df <- psmelt(absolute_glom)
str(absolute_df)
```

```{r, warning=FALSE, include=FALSE}
absolute_df$Phylum <- as.factor(absolute_df$Phylum)
phylum_colors_abs<-colorRampPalette(brewer.pal(8,"Dark2")) (length(levels(absolute_df$Phylum)))
```

```{r, warning=FALSE}
absolute_plot <- ggplot(data= absolute_df, aes(x=Sample, y=Abundance, fill=Phylum))+ 
    geom_bar(aes(), stat="identity", position="stack")+
    scale_fill_manual(values = phylum_colors_abs)
plot(absolute_plot)
```

```{r, warning=FALSE}
percentages_df$Phylum <- as.factor(percentages_df$Phylum)
phylum_colors_rel<- colorRampPalette(brewer.pal(8,"Dark2")) (length(levels(percentages_df$Phylum)))
relative_plot <- ggplot(data=percentages_df, aes(x=Sample, y=Abundance, fill=Phylum))+ 
    geom_bar(aes(), stat="identity", position="stack")+
    scale_fill_manual(values = phylum_colors_rel)
absolute_plot
relative_plot
```

```{r, warning=FALSE, include=FALSE}
percentages_df$Phylum <- as.character(percentages_df$Phylum) # Return the Phylum column to be of type character
percentages_df$Phylum[percentages_df$Abundance < 0.5] <- "Phyla < 0.5% abund."
unique(percentages_df$Phylum)
```

```{r, include=FALSE, warning=FALSE}
percentages_df$Phylum <- as.character(percentages_df$Phylum) # Return the Phylum column to be of type character
percentages_df$Phylum[percentages_df$Abundance < 0.5] <- "Phyla < 0.5% abund."
unique(percentages_df$Phylum)
```

```{r}
percentages_df$Phylum <- as.factor(percentages_df$Phylum)
phylum_colors_rel<- colorRampPalette(brewer.pal(8,"Dark2")) (length(levels(percentages_df$Phylum)))
relative_plot <- ggplot(data=percentages_df, aes(x=Sample, y=Abundance, fill=Phylum))+ 
  geom_bar(aes(), stat="identity", position="stack")+
  scale_fill_manual(values = phylum_colors_rel)
absolute_plot
relative_plot
```


# Referencias:

1. https://carpentries-lab.github.io/metagenomics-analysis/07-phyloseq/index.html
2. https://github.com/FFranciscoEspinosa/bioinformatica_2024/tree/main
