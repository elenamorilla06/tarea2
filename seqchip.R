args_script <- commandArgs(trailingOnly = T)
res_dir <- as.character(args_script[[1]])
print(res_dir)
ins_dir <- as.character(args_script[[2]])
print(ins_dir)


# Para determinar genes diana:

## Paquetes necesarios y asignación de la anotación a una variable:

library(ChIPseeker)
library(TxDb.Athaliana.BioMart.plantsmart28)

txdb <- TxDb.Athaliana.BioMart.plantsmart28

## Lectura del fichero que contiene los picos:

my.peaks <- readPeakFile(peakfile = "intersected.narrowPeak",header = FALSE)

## Definir la región considerada promotor de cara al gen:

promoter <- getPromoters(TxDb = txdb,upstream = 1000,downstream = 1000)

## Anotación de los picos:

peakAnno <- annotatePeak(peak = my.peaks,tssRegion = c(-1000,1000),TxDb = txdb)


# Representación y análisis de la distribución cistrómica global:

## Diagrama de sectores:

png("cistrome_pieplot.png")
plotAnnoPie(peakAnno)
dev.off()

## Diagrama de barras:

png("cistrome_barplot.png")
plotAnnoBar(peakAnno)
dev.off()

## Diagrama de distancia al Transcription Start Site (TSS):

png("cistrome_disttotss.png")
plotDistToTSS(peakAnno,title = "Distribution of genomic loci relative to TSS",ylab = "Genomic Loci (%) (5' -> 3')")
dev.off()

## UpSet plot:

png("cistrome_upsetplot.png")
upsetplot(peakAnno)
dev.off()


# Determinación del reguloma:

## Conversión de la anotación a data frame:

annotation <- as.data.frame(peakAnno)
head(annotation)

## Extracción a una variable de los genes cuyos FT quedan unidos a promotores (zonas más probables de unión):

target.genes <- annotation$geneId[annotation$annotation == "Promoter"]

## Extracción de dichos genes a un archivo de texto:

write(x = target.genes,file = "target_genes.txt")


# Análisis de enriquecimiento funcional en términos de Ontología Génica (GO):

## Paquetes necesarios:

library (clusterProfiler)
library (org.At.tair.db)
library (enrichplot)

## Análisis de enriquecimiento funcional:

enrich.go <- enrichGO(gene = target.genes,OrgDb = org.At.tair.db,ont = "BP",pAdjustMethod = "BH",pvalueCutoff = 0.05,readable = FALSE,keyType = "TAIR")

## Representaciones gráficas de los resultados obtenidos:

### Diagrama de barras:

png("GO_barplot.png")
barplot(enrich.go,showCategory = 15)
dev.off()

### Diagrama de puntos:

png("GO_dotplot.png")
dotplot(enrich.go,showCategory = 15)
dev.off()

### Mapa de enriquecimiento:

png("GO_emapplot.png")
emapplot(pairwise_termsim(enrich.go),showCategory = 15,cex_label_category = 0.5)
dev.off()

### Diagrama de red:

png("GO_cnetplot.png")
cnetplot(enrich.go,showCategory = 15)
dev.off()


# Análisis de enriquecimiento metabólico (KEGG):

enrich.kegg <- enrichKEGG(gene = target.genes,organism = "ath",pAdjustMethod = "BH",pvalueCutoff = 0.05)

## Conversión de resultados a data frame:

df.enrich.kegg <- as.data.frame(enrich.kegg)
head(df.enrich.kegg)

## Exportar resultados a fichero CSV:

write.table(df.enrich.kegg,"enrich.kegg.csv")
