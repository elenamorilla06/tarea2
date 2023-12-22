#! /bin/bash
#SBATCH --export=ALL

INPUTDIR=$1
i=$2
INSDIR=$3
WD=$4
EXP=$5
CHIPDIR=$6
TF=$7

echo ""
echo "========================="
echo "PROCESANDO MUESTRAS INPUT"
echo "========================="
echo ""

echo "TF: $TF"
# Entramos en el directorio del input (donde vamos a almacenar nuestros inputs)
cd $INPUTDIR

# Iterar sobre los archivos con la terminación fq.gz
for archivo in $INPUTDIR/input_*.fq.gz
do
    # Extraer el número del nombre del archivo
    i=$(echo "$archivo" | grep -oP '(?<=input_)\d+(?=\.fq\.gz)')

    # Verificar si se extrajo un número válido (con la expresión $i =~ ^[0-9]+$, verificamos que i sea un número, teniendo la posibilidad de tener entre 1 y 9 muestras, se puede cambiar según el número de muestras que tengamos)
    # Realizamos los análisis de calidad con fastqc para cada muestra
    if [[ $i =~ ^[0-9]+$ ]]
    then
        echo "Procesando archivo: $archivo"
        echo "Número: $i"
        fastqc input_$i.fq.gz
       	# Mapeo de las lecturas al genoma de referencia (generamos el archivo .sam)
        bowtie2 -x ../../genome/index -U input_$i.fq.gz -S input_$i.sam
        # Generamos el .bam a partir del .sam
        samtools sort -o input_$i.bam input_$i.sam
        # Borramos el .sam para reducir espacio
        rm input_$i.sam

        echo "Se ha procesado input $i"
         #Hacemos que NUMPROC contenga el número de líneas en el archivo peaks_list.txt. Esto es necesario para asegurar que el peak.list sea igual al número total de muestras (y solo así se lance el ejecutable peak.sh)
	echo ${INPUTDIR}/input_$i.bam >> ../../results/peaks_list.txt
	NUMPROC=$(wc -l ../../results/peaks_list.txt | awk '{print($1)}')

    else
        echo "No se pudo extraer un número válido del archivo: $archivo"
    fi
done


echo ""
echo "=========================="
echo "MUESTRAS INPUT TERMINADAS"
echo "=========================="
echo ""


echo ""
echo "================================"
echo "HACIENDO EL MERGE DE LOS  INPUTS"
echo "================================"
echo ""

# Con samtools merge generamos el merged de los inputs (colocando en input los .bam obtenidos previamente)
samtools merge input_merge.bam *.bam

echo ""
echo "=================="
echo "MERGE COMPLETADO"
echo "=================="
echo ""

# Con este if se realiza lo que se mencionó anteriormente. De esta forma el peak.sh se ejecutará cuando peaks_list sea igual al número de muestras totales que tenemos (suma de chips e inputs, en este caso 6). El 6 habrá que cambiarlo según nuestro número de muestras (como indica el README)
if [ $NUMPROC -eq 6 ]
then
	echo "Todas las muestras han sido procesadas"
        # Salimos de input/samples y entramos en la carpeta results (donde queremos que se nos guarden los resultados del procesamiento de los picos
	cd ../../
	cd results
	# Se ejecuta el peaks.sh generando los correspondientes txt que nos permitan seguir el procesado y ver los posibles errores 
	sbatch --job-name=peaks --output=peaks_out.txt --error=peaks_err.txt $INSDIR/peaks.sh $WD/$EXP/results $INSDIR $CHIPDIR $INPUTDIR $TF
fi




