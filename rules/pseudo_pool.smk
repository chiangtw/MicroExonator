import glob, os
import random
import csv
import gzip
from collections import defaultdict


def partition (list_in, n):  # Function to do random pooling
    random.shuffle(list_in)
    return [list_in[i::n] for i in range(n)]

n_sb = 5

cluster_files_pb = dict()

for cluster, files in cluster_files.items():
    sb = 1
    for pool in partition(files, n_sb):
        cluster_files_pb[(cluster, sb)] = pool
        sb += 1

def get_files_by_cluster_pb(cluster, ext):
    path="FASTQ/"
    return([path + x + ext for x in cluster_files_pb[cluster]])

rule quant_pool_pb:
    input:
        fastq = lambda w: get_files_by_cluster_pb[(w.cluster, w.pool_ID)],
        index = "Whippet/Index/whippet.jls"
    output:
        "Whippet/Quant/Single_Cell/Pseudo_bulks/{cluster}_{pool_ID}.gene.tpm.gz",
        "Whippet/Quant/Single_Cell/Pseudo_bulks/{cluster}_{pool_ID}.isoform.tpm.gz",
        "Whippet/Quant/Single_Cell/Pseudo_bulks/{cluster}_{pool_ID}.jnc.gz",
        "Whippet/Quant/Single_Cell/Pseudo_bulks/{cluster}_{pool_ID}.map.gz",
        "Whippet/Quant/Single_Cell/Pseudo_bulks/{cluster}_{pool_ID}.psi.gz"
    params:
        bin = config["whippet_bin_folder"],
        output = "Whippet/Quant/Single_Cell/Pseudo_bulks/{cluster}_{pool_ID}"
    priority: 10
    shell:
        "julia {params.bin}/whippet-quant.jl <( cat {input.fastq} ) --force-gz -x {input.index}  -o {params.output}"
        
        
rule get_pseudo_pools:
    input:
        "Whippet/Quant/Single_Cell/Pseudo_bulks/{cluster}_{pool_ID}.psi.gz"
        
