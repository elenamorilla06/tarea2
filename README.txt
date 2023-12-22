Bash scripting 


En la siguiente carpeta vamos a encontrar los scripts y datos necesarios a la hora de llevar a cabo el análisis de los datos obtenidos mediante ChIP-seq. Además, también se encuentra la carpeta test, que contiene el archivo params.txt. Tal y como veremos más adelante, al ejecutar el script seqchip.sh, se va a generar una carpeta que recibirá el nombre del experimento, el cual se le habrá proporcionado de forma previa a la ejecución de los scripts. Esta carpeta va a ser la que contenga los datos pertenecientes a nuestro flujo de trabajo. 


Modificación del archivo params.txt acorde a nuestro estudio


Params.txt: se trata de un archivo de texto donde se encuentran contenidas las rutas de nuestras distintas carpetas que van a dar lugar a nuestro espacio de trabajo. Se indican: 


* Rutas de dónde se van a encontrar los chip, los input, nuestro genoma de estudio, la anotación y el nombre del experimento.  


path_chip: ruta global a los ficheros chip 


path_input: ruta global a los ficheros input


path_genome: ruta global al fichero del genoma 


path_annotation: ruta global a la anotación del genoma


experiment_name: nombre que le vamos a dar a nuestro experimento. Será el nombre que reciba la carpeta que contenga nuestro espacio de trabajo, resultante de ejecutar el fichero seqchip.sh.


working_directory: ruta global al directorio de trabajo, donde se va a llevar a cabo la creación de nuestro espacio de trabajo. 


installation_directory: ruta global del directorio de instalación. Aquí es donde se encuentran los scripts.


* Finalmente, procedemos a indicar si nuestro estudio trata o no sobre un factor de transcripción. 


TF: indicación de si estamos trabajando con factores de transcripción (pondremos TF: TRUE) o, en su defecto, con marcas epigenéticas (TF: FALSE). 


*Es importante dejar un espacio entre el parámetro y la ruta, justo después de los dos puntos (:). 




En cuanto a los scripts: 


seqchip.sh: cuando se ejecute, va a llevar a cabo la creación del espacio de trabajo (con todas las carpetas correspondientes), creación del índice del genoma y de la anotación y, posteriormente, se ejecutarán los scripts chip_proc.sh e  input_proc.sh. 


chip_proc.sh: se va a encargar de procesar las muestras chip, llevando a cabo el análisis de calidad, el  mapeado de las lecturas cortas de referencia y generando los .sam y los .bam. Nosotros proporcionamos un script para un número de muestras entre 1-9. En el caso de disponer de un número de muestras superior, es necesario modificar este script, concretamente el límite superior del intervalo (situado en la primera estructura de control “if”). 


input_proc.sh: se va a encargar de procesar las muestras input, llevando a cabo el análisis de calidad, el mapeo de las lecturas con el genoma de referencia y generando los .sam y los .bam. Además, también se lleva a cabo el merge de los input. Nosotros proporcionamos un script para un número de muestras entre 1-9. En el caso de disponer de un número de muestras superior, es necesario modificar este script, concretamente el límite superior del intervalo (situado en la primera estructura de control “if”). Además, en el último “if” que aparece, se especifica $NUMPROC -eq 6. Este número de muestras tiene que ser la suma total de todas las muestras de las que dispongamos (suma de chip e input, teniendo en cuenta las réplicas*), por tanto, es otro parámetro que será necesario modificar según las características del estudio a llevar a cabo. 




*Por ejemplo: nosotros disponemos de 3 muestras de chip y 3 muestras de input, por lo que el valor que le hemos dado es de 6.


peaks.sh: se encarga de llevar a cabo la determinación de los picos o el peak calling. Es común para las muestras chip e input. Así mismo, en este caso también hemos proporcionado un número de muestras localizado en el intervalo 1-9. Modificar el límite superior si es necesario. 


seqchip.R: para llevar a cabo el análisis matemático-computacional de los datos en R. 






El  único script que vamos a ejecutar nosotros manualmente es seqchip.sh, para lo que vamos a necesitar el params.txt ubicado en la carpeta test. La ejecución se lleva a cabo mediante el siguiente comando: 


./seqchip.sh test/params.txt




Cuando lo ejecutemos va a a suceder lo siguiente: 


creación del flujo de trabajo > procesamiento de las muestras > determinación de picos  > análisis en R
 


Flujo de trabajo 


Lo primero que se ha de hacer es cargar las muestras del estudio (muestras, genoma…) usando sus ubicaciones. Esto habrá de ser indicado y especificado en el fichero params.txt ubicado en la carpeta test.


Con el mismo procedimiento, obtenemos igualmente el número de inputs (ya sean inputs o mocks) y de muestras. 


También es necesario indicar si el análisis que se va a llevar a cabo va a ser para factores de transcripción o, en su defecto, para marcas epigenéticas (que también se lleva a cabo desde el fichero params.txt). 




Comenzamos creando el espacio de trabajo, que va a estar compuesto por distintas carpetas separadas, en las que se depositarán posteriormente los distintos archivos. 


La carpeta genome contiene el genoma, mientras que la carpeta annotation va a contener la anotación del genoma de referencia. Así, podremos llevar a cabo la comparación y mapeado de las lecturas posteriormente. 


Mientras tanto, en la carpeta samples vamos a encontrar distintas subcarpetas repartidas de la siguiente forma: en la subcarpeta chip vamos a encontrar las muestras chip, mientras que en la subcarpeta input, los inputs. 


Por otro lado, en la carpeta results se van a encontrar todos los archivos resultantes del análisis llevado a cabo.




Llamada a sbatch para: 


* Procesamiento de las muestras 


Una vez que se ha creado el espacio de trabajo, se crea el índice del genoma. Se llama al script sample_proc.sh para el procesamiento de las muestras chip y, paralelamente, también se llama al script input_proc.sh para el procesamiento de los inputs. De la ejecución de estos scripts se encarga nuestro gestor de colas: SLURM. 




* Determinación de los picos 


Se llama a sbatch para ejecutar el script peaks.sh, donde se va a llevar a cabo el merge (unificación de todos los inputs en el caso de que tengamos más de uno). Además, se comparan los picos de cada muestra con el merge, lo que nos va a permitir determinar los picos. 


Finalmente, siempre y cuando contemos con más de una muestra, usamos bedtools para unir todos los picos. Es decir, va a unir todos los archivos .narrowPeak en un único archivo intersected.narrowPeak.




Análisis matemático-computacional en R 


Con el intersected.narrowPeak se ejecuta el script de R seqchip.R, lo que nos va a permitir llevar a cabo el análisis matemático-computacional de los datos de nuestro estudio. 


Dentro de este análisis, encontramos un análisis de la distribución global del cistroma, determinación del reguloma y análisis de enriquecimiento funcional, incluyendo también el de las vías metabólicas, lo que nos permitirá encontrar vías metabólicas enriquecidas. 


Finalmente, para acabar con el análisis, la herramienta HOMER nos va a permitir llevar a cabo un análisis de enriquecimiento de motivos de ADN en los sitios de unión de nuestro FT de estudio. Es por ello, que esto solo habrá de llevarse a cabo para factores de transcripción, no para marcas epigenéticas. 


**IMPORTANTE**

Cabe apreciar que, al ejecutar el script de R desde el terminal de MobaXterm, los archivos correspondientes a representaciones gráficas, .csv y .txt de los resultados obtenidos del análisis no aparecen en la carpeta de resultados, posiblemente por el procesamiento del script por una versión obsoleta de R. El usuario deberá descargar tanto el script de R como el archivo intersected.narrowPeak y ejecutar desde RStudio el script completo para comprobar que, efectivamente, dichos archivos se generan y poder visualizar gráficamente los resultados.
