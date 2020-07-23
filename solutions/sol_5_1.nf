/* 
 * pipeline input parameters 
 */
params.reads = "$baseDir/../data/ggal/gut_{1,2}.fq"
params.transcriptome = "$baseDir/../data/ggal/transcriptome.fa"
params.multiqc = "$baseDir/../multiqc"
params.outdir = "results"

log.info """\
         R N A S E Q - N F   P I P E L I N E    
         ===================================
         transcriptome: ${params.transcriptome}
         reads        : ${params.reads}
         outdir       : ${params.outdir}
         """
         .stripIndent()

/* 
 * create a transcriptome file object given then transcriptome string parameter
 */
transcriptome_file = file(params.transcriptome)
 
/* 
 * define the `index` process that create a binary index 
 * given the transcriptome file
 */
process index {
    
    input:
    file transcriptome from transcriptome_file
     
    output:
    file 'index' into index_ch

    script:       
    """
    salmon index --threads $task.cpus -t $transcriptome -i index
    """
}


Channel 
    .fromFilePairs( params.reads, checkIfExists:true )
    .into { read_pairs_quanti ;  read_pairs_fastqc} 

process quantification {
     
    input:
    file index from index_ch
    set pair_id, file(reads) from read_pairs_quanti
 
    output:
    file(pair_id) into quant_ch
 
    script:
    """
    salmon quant --threads $task.cpus --libType=U -i $index -1 ${reads[0]} -2 ${reads[1]} -o $pair_id
    """
}

process fastqc {
    tag "FASTQC on $sample_id"

    input:
    set sample_id, file(reads) from read_pairs_fastqc

    output:
    file("fastqc_${sample_id}_logs") into fastqc_ch


    script:
    """
    mkdir fastqc_${sample_id}_logs
    fastqc -o fastqc_${sample_id}_logs -f fastq -q ${reads}
    """  
}  