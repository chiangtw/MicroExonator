if config.get("only_db", False):  #This allows to just quantify microexons from annotation and database sources
    
    rule Micro_Exon_Tags:
        input:
            "Round1/ME_TAGs.fa"
        params:
            "NA"
        output:
            "Round2/ME_canonical_SJ_tags.de_novo.fa"
        conda:
            "../envs/core.yaml"
        shell:
            "python2 src/Micro_exons_tags.py  {input} {params} > {output}"
            
            
    if config.get("split_DB", False):
                    
        rule split_ME_DB:
            input:
                config["ME_DB"]
            output:
                dynamic("data/splits/ME_DB.{split}")
            shell:
                "split -l 5000 {input} data/splits/ME_DB."
                
                
        if config["conservation_bigwig"].split("/")[0]=="NA":

            rule Get_ME_from_annotation_ref:
                input:
                    genome = config["Genome_fasta"],
                    bed12 = config["Gene_anontation_bed12"],
                    GTAG_5 = "data/GT_AG_U2_5.pwm",
                    GTAG_3 = "data/GT_AG_U2_3.pwm",
                    ME_DB = config["ME_DB"]
                params:
                    bw = config["conservation_bigwig"],
                    ME_centric = "NA",
                    ME_len = config["ME_len"],
                    mode = "db_ref"
                output:
                    "data/splits/ref.ME_canonical_SJ_tags.DB.fa",
                    "data/splits/ref.DB.ME_centric",
                    "data/splits/ref.non_overlap"
                conda:
                    "../envs/pybedtools.yaml"
                shell:
                    "python2 src/Get_annotated_microexons_dynamic.py {input.genome} {params.ME_centric} {input.bed12} {input.GTAG_5} {input.GTAG_3} {params.bw} {params.ME_len} {input.ME_DB} {params.mode} {output}"                  
               
            rule Get_ME_from_annotation_split:
                input:
                    genome = config["Genome_fasta"],
                    bed12 = config["Gene_anontation_bed12"],
                    GTAG_5 = "data/GT_AG_U2_5.pwm",
                    GTAG_3 = "data/GT_AG_U2_3.pwm",
                    ME_DB = "data/splits/ME_DB.{split}"
                params:
                    bw = config["conservation_bigwig"],
                    ME_centric = "NA",
                    ME_len = config["ME_len"],
                    mode = "db_split"
                output:
                    "data/splits/ME_canonical_SJ_tags.DB.fa.{split}",
                    "data/splits/DB.ME_centric.{split}",
                    "data/splits/non_overlap.{split}"
                conda:
                    "../envs/pybedtools.yaml"
                shell:
                    "python2 src/Get_annotated_microexons_dynamic.py {input.genome} {params.ME_centric} {input.bed12} {input.GTAG_5} {input.GTAG_3} {params.bw} {params.ME_len} {input.ME_DB} {params.mode} {output}"

        else:

            rule Get_ME_from_annotation_ref:
                input:
                    genome = config["Genome_fasta"],
                    bed12 = config["Gene_anontation_bed12"],
                    GTAG_5 = "data/GT_AG_U2_5.pwm",
                    GTAG_3 = "data/GT_AG_U2_3.pwm",
                    ME_DB = config["ME_DB"],
                    bw = config["conservation_bigwig"]
                params:
                    ME_centric = "NA",
                    ME_len = config["ME_len"],
                    mode = "db_ref"
                output:
                    "data/splits/ref.ME_canonical_SJ_tags.DB.fa",
                    "data/splits/ref.DB.ME_centric",
                    "data/splits/ref.non_overlap"
                conda:
                    "../envs/pybedtools.yaml"
                shell:
                    "python2 src/Get_annotated_microexons_dynamic.py {input.genome} {params.ME_centric} {input.bed12} {input.GTAG_5} {input.GTAG_3} {input.bw} {params.ME_len} {input.ME_DB} {params.mode} {output}"                  
 
            rule Get_ME_from_annotation_split:
                input:
                    genome = config["Genome_fasta"],
                    bed12 = config["Gene_anontation_bed12"],
                    GTAG_5 = "data/GT_AG_U2_5.pwm",
                    GTAG_3 = "data/GT_AG_U2_3.pwm",
                    ME_DB = "data/splits/ME_DB.{split}",
                    bw = config["conservation_bigwig"]
                params:
                    ME_centric = "NA",
                    ME_len = config["ME_len"],
                    mode = "db_split"
                output:
                    "data/splits/ME_canonical_SJ_tags.DB.fa.{split}",
                    "data/splits/DB.ME_centric.{split}",
                    "data/splits/non_overlap.{split}"
                conda:
                    "../envs/pybedtools.yaml"
                shell:
                    "python2 src/Get_annotated_microexons_dynamic.py {input.genome} {params.ME_centric} {input.bed12} {input.GTAG_5} {input.GTAG_3} {input.bw} {params.ME_len} {input.ME_DB} {params.mode} {output}"
                    

        rule ME_DB_splits_output:
            input:
                ref_SJ_tags = "data/splits/ref.ME_canonical_SJ_tags.DB.fa",
                ref_ME_centric = "data/splits/ref.DB.ME_centric",
                splits_SJ_tags = dynamic("data/splits/ME_canonical_SJ_tags.DB.fa.{split}"),
                splits_ME_centric = dynamic("data/splits/DB.ME_centric.{split}")
            output:
                SJ_tags = "data/ME_canonical_SJ_tags.DB.fa",
                ME_centric = "data/DB.ME_centric"
            shell:
                "cat {input.ref_SJ_tags} {input.splits_SJ_tags} > {output.SJ_tags} && cat {input.ref_ME_centric} {input.splits_ME_centric} > {output.ME_centric}" 
            
    else:
    
        rule Get_ME_from_annotation:
            input:
                genome = config["Genome_fasta"],
                bed12 = config["Gene_anontation_bed12"],
                GTAG_5 = "data/GT_AG_U2_5.pwm",
                GTAG_3 = "data/GT_AG_U2_3.pwm",
                ME_DB = config["ME_DB"]
            params:
                bw = config["conservation_bigwig"],
                ME_centric = "NA",
                ME_len = config["ME_len"]
            output:
                "data/ME_canonical_SJ_tags.DB.fa",
                "data/DB.ME_centric"
            conda:
                "../envs/pybedtools.yaml"
            shell:
                "python2 src/Get_annotated_microexons.py  {input.genome} {params.ME_centric} {input.bed12} {input.GTAG_5} {input.GTAG_3} {params.bw} {params.ME_len} {input.ME_DB} "    

                
    if  str2bool(config.get("skip_get_SJ_tags_round2", False)):
        pass
    else:   
        rule merge_tags:
            input:
                "Round2/ME_canonical_SJ_tags.de_novo.fa",
                "data/ME_canonical_SJ_tags.DB.fa"
            output:
                "Round2/ME_canonical_SJ_tags.fa"
            conda:
                "../envs/core.yaml"
            shell:
                "cat {input[0]} {input[1]} > {output}"

        rule merge_ME_centric:
            input:
                "data/DB.ME_centric"
            output:
                "Round2/TOTAL.ME_centric.txt"
            conda:
                "../envs/core.yaml"
            shell:
                "cat {input} > {output}"            
            
else:
    
    rule Micro_Exon_Tags:
        input:
            "Round1/ME_TAGs.fa",
            "Round1/TOTAL/TOTAL.sam.row_ME.filter1.ME_centric"
        output:
            "Round2/ME_canonical_SJ_tags.de_novo.fa"
        conda:
            "../envs/core.yaml"
        shell:
            "python2 src/Micro_exons_tags.py  {input} > {output}"
    
    rule Get_ME_from_annotation:
        input:
            config["Genome_fasta"],
            "Round1/TOTAL/TOTAL.sam.row_ME.filter1.ME_centric",
            config["Gene_anontation_bed12"],
            "data/GT_AG_U2_5.pwm",
            "data/GT_AG_U2_3.pwm",
            config["ME_DB"]
        params:
            bw = config["conservation_bigwig"],
            ME_len = config["ME_len"]
        output:
            "data/ME_canonical_SJ_tags.DB.fa",
            "data/DB.ME_centric"
        conda:
            "../envs/pybedtools.yaml"
        shell:
            "python2 src/Get_annotated_microexons.py  {input[0]} {input[1]} {input[2]} {input[3]} {input[4]} {params.bw} {params.ME_len} {input[5]} "    
    
    rule merge_tags:
        input:
            "Round2/ME_canonical_SJ_tags.de_novo.fa",
            "data/ME_canonical_SJ_tags.DB.fa"
        output:
            "Round2/ME_canonical_SJ_tags.fa"
        conda:
            "../envs/core.yaml"
        shell:
            "cat {input[0]} {input[1]} > {output}"

    rule merge_ME_centric:
        input:
            "Round1/TOTAL/TOTAL.sam.row_ME.filter1.ME_centric",
            "data/DB.ME_centric"
        output:
            "Round2/TOTAL.ME_centric.txt"
        conda:
            "../envs/core.yaml"
        shell:
            "cat {input[0]} {input[1]} > {output}"

EBWT = ["1.ebwt", "2.ebwt", "3.ebwt", "4.ebwt", "rev.1.ebwt", "rev.2.ebwt" ]
           
rule Round2_bowtie_tags_index:
    input:
        "Round2/ME_canonical_SJ_tags.fa"
    output:
        expand("Round2/ME_canonical_SJ_tags.fa.{ebwt}", ebwt=EBWT)
    conda:
        "../envs/core.yaml"
    shell:
        "bowtie-build {input} {input}"

rule download_fastq2:
    input:
        "download/{sample}.download.sh",
        "Round2/TOTAL.ME_centric.txt"
    params:
        "FASTQ/{sample}.fastq"
    output:
        temp("FASTQ/round2/{sample}.fastq")
    priority: -10
    resources: 
        get_data = 1
    conda:
        "../envs/core.yaml"
    shell:
        #"bash {input[0]}"
        "bash {input[0]} && mv {params} {output}"

def hard_drive_behavior(fastq):
    if config.get("Optimize_hard_drive", False)=="T":
    
        if "validate_fastq_list" in config:
        
            to_validate = set[()]
            
            with open(config["validate_fastq_list"]) as fastq_list:
                reader = csv.reader(fastq_list, delimiter="\t")
                for row in reader:
                    to_validate.add(row[0])
                    
            if fastq in to_validate:
                return("FASTQ/round2/" + fastq + ".fastq.gz.valid")
            else:
                return(  "FASTQ/round2/" + fastq + ".fastq.gz")
                
        else:
            return(  "FASTQ/round2/" + fastq + ".fastq.gz")
    else:

        if "validate_fastq_list" in config:
        
            to_validate = set([])
            
            with open(config["validate_fastq_list"]) as fastq_list:
                reader = csv.reader(fastq_list, delimiter="\t")
                for row in reader:
                    to_validate.add(row[0])
                    
            if fastq in to_validate:
                return("FASTQ/" + fastq + ".fastq.gz.valid")
            else:
                return(  "FASTQ/" + fastq + ".fastq.gz")
        else:

            return("FASTQ/" + fastq + ".fastq.gz")


rule validate_fastq:
    input:
        "FASTQ/{sample}.fastq.gz"
    output:
        "FASTQ/{sample}.fastq.gz.valid"
    shell:
        "python3 src/validate_fastq.py {input}"
    
rule validate_fastq2:
    input:
        "FASTQ/round2/{sample}.fastq.gz"
    output:
        "FASTQ/round2/{sample}.fastq.gz.valid"
    shell:
        "python3 src/validate_fastq.py {input}"

rule Round2_bowtie_to_tags:
    input:
        "Round2/ME_canonical_SJ_tags.fa",
        hard_drive_behavior("{sample}"),
        expand("Round2/ME_canonical_SJ_tags.fa.{ebwt}", ebwt=EBWT)
    output:
        temp("Round2/{sample}.sam")
    threads: 5
    priority: 100
    conda:
        "../envs/core.yaml"
    shell:
        "gzip -dc {input[1]} |  bowtie {input[0]} -p {threads} -q - -S -v 2 --seed 123 | awk '!($6 ~ /I/) && !($6 ~ /D/) && !($6 ~ /S/) && !($6 ~ /*/)' > {output}"


rule Round2_alingment_pre_processing:
    input:
        "Round2/{sample}.sam"
    output:
        temp("Round2/{sample}.sam.pre_processed")
    priority: 100
    conda:
        "../envs/core.yaml"
    shell:
        "python2 src/alingment_pre_processing_round2_bowtie.py {input} F > {output}"
        
        
rule Round2_ME_evidence:
    input:
        "Round2/{sample}.sam"
    output:
        "Round2/ME_reads/{sample}.ME_spanning_reads.tsv"
    priority: 100
    conda:
        "../envs/core.yaml"
    shell:
        "python2 src/get_ME_spaning_reads.py {input} F > {output}"
        
rule get_all_spanning_reads:
    input:
        expand("Round2/ME_reads/{sample}.ME_spanning_reads.tsv", sample=DATA)
        
       