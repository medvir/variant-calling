# define input
IDS, = glob_wildcards("raw_data/{id}.fastq.gz")

# target rule
rule all:
    input:
        expand("call_variants/{id}.vcf", id=IDS)

# rules
rule sample_reads:
    input:
        "raw_data/{id}.fastq.gz"
    output:
        "raw_data_sampled/{id}_sampled.fastq"
    conda:
        "envs/sample_reads.yaml"
    shell:
        "seqkit sample -n 200000 {input} -o {output}"

rule map_to_ref:
    input:
        ref = "raw_data/ref.fasta",
        fastq = "raw_data_sampled/{id}_sampled.fastq"
    output:
        temp("mapped_reads/{id}.bam")
    conda:
        "envs/map_to_ref.yaml"
    shell:
        """
        bwa index {input.ref}
        bwa mem {input.ref} {input.fastq} | samtools view -u | samtools sort -o {output}
        """

rule indelqual:
    input:
        ref = "raw_data/ref.fasta",
        bam = "mapped_reads/{id}.bam"
    output:
        "mapped_reads/{id}_indelqual.bam"
    conda:
        "envs/indelqual.yaml"
    shell:
        "lofreq indelqual --dindel --ref {input.ref} {input.bam} -o {output}"

rule call_variants:
    input:
        ref = "raw_data/ref.fasta",
        bam = "mapped_reads/{id}_indelqual.bam"
    output:
        "call_variants/{id}.vcf"
    conda:
        "envs/call_variants.yaml"
    shell:
        """
        lofreq faidx {input.ref}
        samtools index {input.bam}
        lofreq call --call-indels -f {input.ref} -o {output} {input.bam}
        """
