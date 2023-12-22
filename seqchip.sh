#! /bin/bash

if [ $# -ne 1 ]
then
	echo "El numero de argumentos es: $#"
	echo "Uso: seqchip.sh <params.txt> <numero de muestras chip> <numero de muestras input>"
	echo ""
	echo "params.txt: Archivo de entrada con argumentos"
	echo "Un ejemplo de  params.txt se puede encontrar en la carpeta test"
	exit
fi

PARAMS=$1

echo ""
echo "===================="
echo "CARGANDO PARAMETROS "
echo "===================="
echo ""

# Vamos a extraer y almacenar el valor asociado a las diferentes etiquetas (working_directory, installation_directory, experiment_name...) en las diferentes variables (WD, INSDIR, EXP...)
WD=$(grep working_directory $PARAMS | awk '{print($2)}')
echo "Working directory: $WD"

INSDIR=$(grep installation_directory $PARAMS | awk '{print($2)}')
echo "Installation directory: $INSDIR"

EXP=$(grep experiment_name $PARAMS | awk '{print($2)}')
echo "Experiment name: $EXP"

GENOME=$(grep path_genome $PARAMS | awk '{print($2)}')
echo "Genome path: $GENOME"

ANNOT=$(grep path_annotation $PARAMS | awk '{print($2)}')
echo "Annotation path: $ANNOT"


CHIP=$(grep path_chip $PARAMS | awk '{print($2)}')
echo "Chip path: $CHIP"
INPUT=$(grep path_input $PARAMS | awk '{print($2)}')
echo "Input path: $INPUT"

TF=$(grep TF $PARAMS | awk '{print($2)}')
echo "TF: $TF"

echo ""
echo "============================"
echo " CREANDO ESPACIO DE TRABAJO "
echo "============================"
echo ""

#Generamos el espacio de trabajo
cd $WD
mkdir $EXP
cd $EXP
mkdir genome annotation results samples
cd samples
mkdir chip input
cd ..

cp $GENOME genome/genome.fa
cp $ANNOT annotation/annotation.gtf
cd samples
cd chip
# Patrón para buscar archivos de muestras en el directorio de origen (por ejemplo, "*.muestra")
patron=*.fq.gz
# Bucle for para copiar las muestras
for muestra in $CHIP/$patron
do
    # Verifica si el patrón coincide con algún archivo en el directorio de origen
    if [ -e $muestra ]
	then
        # Obtiene el nombre del archivo sin la ruta
        nombre_muestra=$(basename $muestra)
        # Copia la muestra al directorio de destino
        cp $muestra .
        echo "Se ha copiado $nombre_muestra."
    	fi
done
cd ..

cd input
# Patrón para buscar archivos de muestras en el directorio de origen (por ejemplo, "*.muestra")
patron=*.fq.gz

# Bucle for para copiar las muestras
for muestra in $INPUT/$patron
do
    # Verifica si el patrón coincide con algún archivo en el directorio de origen
    if [ -e $muestra ]
	then
        # Obtiene el nombre del archivo sin la ruta
        nombre_muestra=$(basename $muestra)
        # Copia la muestra al directorio de destino
        cp $muestra .
        echo "Se ha copiado $nombre_muestra."
    	fi
done
cd ..
cd ..

echo ""
echo "=================================="
echo "CONSTRUYENDO EL INDICE DEL GENOMA "
echo "=================================="
echo ""


# Construimos el índice del genoma entrando en la carpeta genome (cd) y usando la función bowtie2-build
cd genome
bowtie2-build genome.fa index

echo ""
echo "==============="
echo "INDICE GENERADO"
echo "==============="
echo ""

cd ..
cd samples
sbatch  --job-name=proc_chip --output=chip.txt --error=err_chip.txt $INSDIR/chip_proc.sh $WD/$EXP/samples/chip 1 $INSDIR $WD $EXP $i $WD/$EXP/samples/input $TF
sbatch  --job-name=proc_input --output=input.txt --error=err_input.txt $INSDIR/input_proc.sh $WD/$EXP/samples/input 1 $INSDIR $WD $EXP $i $WD/$EXP/samples/chip $TF

