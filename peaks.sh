#! /bin/bash
#SBATCH --export=ALL

RESDIR=$1
INSDIR=$2
CHIPDIR=$3
INPUTDIR=$4
TF=$5

echo ""
echo "================"
echo "GENERANDO PICOS"
echo "================"
echo ""

echo "$TF"

# Iterar sobre los archivos con la terminación .bam
for archivo in $CHIPDIR/chip_*.bam
do
    # Usamos grep para almacenar en i el numero de cada muestra (entre chip y .bam)
    i=$(echo "$archivo" |grep -oP '(?<=chip_)\d+(?=\.bam)')
    # Verificar si se extrajo un número válido (con la expresión $i =~ ^[0-9]+$, verificamos que i sea un número, teniendo la posibilidad de tener entre 1 y 9 muestras, se puede cambiar según el número de muestras que tengamos)
    if [[ $i =~ ^[0-9]+$ ]]
    then
        echo "Procesando archivo: $i"
	# Usamos este if en caso de que nuestra muestra sea un factor de transcripción
	if [ $TF = "TRUE" ]
        then
        	echo "Es un factor de transcripcion"
		# Si no es un factor de transcripción ejecutamos el macs2 callpeaks con la opción --nomodel. Macs2 callpeak permite identificar las reegiones del genoma donde hay enriquecimiento significativo de señales, según dón de se acumulen los picos. --nomodel va a indicar que no se construya un modelo para el tamaño del fragmento de ADN
        	macs2 callpeak -t $CHIPDIR/chip_$i.bam -c $INPUTDIR/input_merge.bam -f BAM --outdir $RESDIR -n picos_[$i]
	else
		echo "Es una marca epigenetica"
		macs2 callpeak -t $CHIPDIR/chip_$i.bam -c $INPUTDIR/input_merge.bam -f BAM --outdir $RESDIR -n picos_[$i] --nomodel
	fi
	echo "Se ha generado picos $i" # Verificar si se extrajo un número válido (con la expresión $i =~ ^[0-9]+$, verificamos que i sea un número, teniendo la posibilidad de tener entre 1 y 9 muestras, se puede cambiar según el número de muestras que tengamos)
    else
        echo "No se pudo extraer un número válido del archivo: $archivo"
    fi
done


# Iterar sobre cada uno de los peaks.narrowPeak
for archivo in $RESDIR/picos_[$i]_peaks.narrowPeak
do
    # De nuevo usamos grep para almacenar en i el número de cada muestra
    i=$(echo "$archivo" | grep -oP '(?<=picos_\[)\d+(?=\]_peaks\.narrowPeak)')
    # De nuevo, verificar si se extrajo un número válido (con la expresión $i =~ ^[0-9]+$, verificamos que i sea un número, teniendo la posibilidad de tener entre 1 y 9 muestras, se puede cambiar según el número de muestras que tengamos)
    if [[ $i =~ ^[0-9]+$ ]]
    then

	# Con este if nos aseguramos que el número de muestras que tenemos es igual o mayor que 2, en cuyo caso realizaremos la intersección de los picos con bedtools intersect
        if [ "$i" -ge 2 ]
        then
            echo "Número de archivos: $i"
            echo "El archivo es $archivo"
	    # En caso de que el número de muestras sea sólo 2 realizaremos el bedtools clásico, colocando en -a el primer archivo peaks.narrowPeak y en -b el segundo
            bedtools intersect -a $RESDIR/picos_[1]_peaks.narrowPeak -b $archivo > intersected.narrowPeak

	    # En caso de que el número de archivos .narrowPeaks que tengamos sea superior a 2 muestras, será necesario modificar el bedtools. Para ello vamos a utilizar el archivo generado en el bedtools intersec anterior (intersected.narrowPeak) como el -a del nuevo bedtools, y el -b será el siguiente archivo .narrowPeak que tengamos, en este caso el 3.
            if [ "$i" -gt 2 ]; then
                bedtools intersect -a intersected.narrowPeak -b $RESDIR/picos_[$i]_peaks.narrowPeak > temporal_intersected.narrowPeak
		# Para poder repetir el bedtools tantas veces como muestras tengamos va a ser necesario usar un mv, con esta función vamos a colocar la intersección generada en el bedtools como argumento de un nuevo bedtools. De esta forma se va a realizar una nueva función donde el -a será la intersección generada en el bedtools anterior y el -b será la siguiente muestra .narrowPeak (en este caso será la muestra 4). Esto se va a repetir para cada muestra .narrowPeak que tengamos
                mv temporal_intersected.narrowPeak intersected.narrowPeak
            fi
        else
            echo "No hay más de un archivo de picos presente en el directorio"
        fi
    else
        echo "No se pudo extraer un número válido del archivo: $archivo"
    fi
done

echo ""
echo "==============="
echo "PICOS GENERADOS"
echo "==============="
echo ""

echo ""
echo "======"
echo "HOMER"
echo "======"
echo ""

	# Esta función va a permitir buscar motivos de unión a proteínas en las regiones de enriquecimiento (intersected.narrowPeak)
	findMotifsGenome.pl intersected.narrowPeak tair10 dnaMotifs -size 100 -len 8


echo ""
echo "===================="
echo "LLAMANDO A R STUDIO"
echo "===================="
echo ""

# Una vez finalizado el procesamiento de los picos llamamos a R para completar el análisis 
Rscript $INSDIR/seqchip.R $RESDIR $INSDIR
