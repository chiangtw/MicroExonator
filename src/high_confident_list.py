import csv
import sys
from collections import defaultdict
from Bio import SeqIO
from Bio.Seq import Seq
from snakemake.utils import min_version
import gzip

Genome = {}

def Genomictabulator(fasta):


	f = open(fasta)

	for chrfa in SeqIO.parse(f, "fasta"):
		Genome[chrfa.id] = chrfa.seq


	f.close()



def main(gene_model_bed12, out_filtered_ME, out_low_scored_ME, PSI_files):

    estart_exons = defaultdict(set)
    eend_exons = defaultdict(set)

    total_ME_up = defaultdict(int)
    total_ME_down = defaultdict(int)

    high_confident_ME = []

    with open(gene_model_bed12) as bedfile, \
        open(out_filtered_ME) as ME_out1, \
        open(out_low_scored_ME) as ME_low1, \
        open(out_filtered_ME) as ME_out, \
        open(out_low_scored_ME) as ME_low:

        reader = csv.reader(bedfile, delimiter="\t")

        for row in reader:

            csv.field_size_limit(1000000000)

            qstarts = list(map (int, row[11].strip(",").split(",")))[1:-1]
            blocksizes = list(map(int, row[10].strip(",").split(",")))[1:-1]

            start = int(row[1])
            strand = row[5]
            bn = int(row[9])
            chrom = row[0]


            for q1, b in zip(qstarts, blocksizes):
                estart = start + q1
                eend = start + q1 + b
                elenght = eend - estart
                exon = (chrom, strand, estart, eend)

                estart_exons[(chrom, strand, estart)].add(exon)
                eend_exons[(chrom, strand, eend)].add(exon)


        #### Counting exons that have the same start/end


        reader = csv.DictReader(ME_out1, delimiter="\t")


        for row in reader:

            chrom = "_".join(row["ME"].split("_")[:-3]) 
            strand, estart, eend = row["ME"].split("_")[-3:]
            exon = (chrom, strand, estart, eend)

            estart_exons[(chrom, strand, estart)].add(exon)
            eend_exons[(chrom, strand, eend)].add(exon)



        reader = csv.DictReader(ME_low1, delimiter="\t")


        for row in reader:

            if row["ME_type"]=="RESCUED":
                
                chrom = "_".join(row["ME"].split("_")[:-3]) 
                strand, estart, eend = row["ME"].split("_")[-3:]
                exon = (chrom, strand, estart, eend)

                estart_exons[(chrom, strand, estart)].add(exon)
                eend_exons[(chrom, strand, eend)].add(exon)


        ## Summing exon coverage


        #reader = csv.reader(ME_out_cov, delimiter="\t")
        
        for file_path in PSI_files:
            
            file = gzip.open(file_path,'rb')
            reader = csv.DictReader(file, delimiter="\t")

            for row in reader:

                #FILE_NAME, ME, total_SJs, ME_SJ_coverages, sum_ME_coverage, sum_ME_SJ_coverage_up_down_uniq, sum_ME_SJ_coverage_up, sum_ME_SJ_coverage_down, SJ_coverages, sum_SJ_coverage, is_alternative_5, is_alternative_3, alternatives_5, cov_alternatives_5, total_cov_alternatives_5, alternatives_3,  cov_alternatives_3, total_cov_alternatives_3 = row
                #chrom = "_".join(row["ME"].split("_")[:-3]) 
                #strand, estart, eend = ME.split("_")[-3:]
                #exon = (chrom, strand, estart, eend)
                #sum_ME_SJ_coverage_up = int(sum_ME_SJ_coverage_up)
                #sum_ME_SJ_coverage_down = int(sum_ME_SJ_coverage_down)

                total_ME_up[row["ME_coords"]] += int(row["sum_ME_SJ_coverage_up"])
                total_ME_down[row["ME_coords"]] += int(row["sum_ME_SJ_coverage_down"])

        ambiguous = open("Report/out.ambiguous.txt", "w")
	
        ambiguous.write( "\t".join(["ME", "Transcript", "Total_coverage", "Total_SJs", "ME_coverages", "ME_length", "ME_seq", "ME_matches", "U2_score",  "Mean_conservation", "P_MEs", "Total_ME",   "ME_P_value", "ME_type"]) + "\n")

        print("ME", "Transcript", "Total_coverage", "Total_SJs", "ME_coverages", "ME_length", "ME_seq", "ME_matches", "U2_score",  "Mean_conservation", "P_MEs", "Total_ME",   "ME_P_value", "ME_type", sep="\t")

        reader = csv.DictReader(ME_out, delimiter="\t")

        for row in reader:

            chrom = "_".join(row["ME"].split("_")[:-3]) 
            strand, estart, eend = row["ME"].split("_")[-3:]
            exon = (chrom, strand, estart, eend)

            sum_ME_SJ_coverage_up = total_ME_up[row["ME"]]
            sum_ME_SJ_coverage_down =  total_ME_down[row["ME"]]

            abs_up_down_diff = "NA"


            # if row["ME"]=="chr11_-_41913982_41913993":
            #
            #     print(len(estart_exons[(chrom, strand, estart)]), len(eend_exons[(chrom, strand, eend)]),  abs(sum_ME_SJ_coverage_up-sum_ME_SJ_coverage_down)/(sum_ME_SJ_coverage_up+sum_ME_SJ_coverage_down) )
            #     print( row["ME"], row["transcript"], row["sum_total_coverage"], row["total_SJs"], row["total_coverages"], row["len_micro_exon_seq_found"], row["micro_exon_seq_found"], row["total_number_of_micro_exons_matches"], row["U2_scores"], row["mean_conservations_vertebrates"], row["P_MEs"], row["total_ME"], row["ME_P_value"], row["ME_type"], sep="\t")
            #

            
            ME_len = int(row["len_micro_exon_seq_found"])
            
            SJ_end_seqs = set([])
            
            for SJ in row["total_SJs"].split(","):  #Checking if sequences at the end of introns matches ME sequences
                
                SJ_chrom = SJ.split(":")[0]
                SJ_start, SJ_end = SJ.split(":")[1].split(strand)
                SJ_start = int(SJ_start)
                SJ_end = int(SJ_end)
                
                SJ_seq_up = str(Genome[SJ_chrom][SJ_start:SJ_start+ME_len]).upper()
                SJ_seq_down = str(Genome[SJ_chrom][SJ_end-ME_len:SJ_end]).upper()
                
                if strand=="-":
                    SJ_seq_up = str(Genome[SJ_chrom][SJ_end-ME_len:SJ_end].reverse_complement()).upper()
                    SJ_seq_down = str(Genome[SJ_chrom][SJ_start:SJ_start+ME_len].reverse_complement()).upper()
                
                if SJ_start!=int(estart) and SJ_end!=int(eend):
                
                    SJ_end_seqs.add(SJ_seq_up)
                    SJ_end_seqs.add(SJ_seq_down)
                

            if sum_ME_SJ_coverage_up+sum_ME_SJ_coverage_down>0:


                abs_up_down_diff = abs(sum_ME_SJ_coverage_up-sum_ME_SJ_coverage_down)/(sum_ME_SJ_coverage_up+sum_ME_SJ_coverage_down)


                if (len(estart_exons[(chrom, strand, estart)]) + len(eend_exons[(chrom, strand, eend)]) > 2) and abs_up_down_diff > 0.95:

                    #ME_black_list.write(row["ME"]+"\n")
                    pass

                elif row["micro_exon_seq_found"] in SJ_end_seqs:
                    ambiguous.write("\t".join([row["ME"], row["transcript"], row["sum_total_coverage"], row["total_SJs"], row["total_coverages"], row["len_micro_exon_seq_found"], row["micro_exon_seq_found"], row["total_number_of_micro_exons_matches"], row["U2_scores"], row["mean_conservations_vertebrates"], row["P_MEs"], row["total_ME"], row["ME_P_value"], row["ME_type"] ]) + "\n" )
                else:
                    print(row["ME"], row["transcript"], row["sum_total_coverage"], row["total_SJs"], row["total_coverages"], row["len_micro_exon_seq_found"], row["micro_exon_seq_found"], row["total_number_of_micro_exons_matches"], row["U2_scores"], row["mean_conservations_vertebrates"], row["P_MEs"], row["total_ME"], row["ME_P_value"], row["ME_type"], sep="\t")


        reader = csv.DictReader(ME_low, delimiter="\t")

        for row in reader:

            chrom = "_".join(row["ME"].split("_")[:-3]) 
            strand, estart, eend = row["ME"].split("_")[-3:]
            exon = (chrom, strand, estart, eend)

            sum_ME_SJ_coverage_up = total_ME_up[row["ME"]]
            sum_ME_SJ_coverage_down =  total_ME_down[row["ME"]]

            abs_up_down_diff = "NA"
            
            
            SJ_end_seqs = set([])
            
            for SJ in row["total_SJs"].split(","):  #Checking if sequences at the end of introns matches ME sequences
				 
                
                SJ_chrom = SJ.split(":")[0]
                SJ_start, SJ_end = SJ.split(":")[1].split(strand)
                SJ_start = int(SJ_start)
                SJ_end = int(SJ_end)
                
                SJ_seq_up = str(Genome[SJ_chrom][SJ_start:SJ_start+ME_len]).upper()
                SJ_seq_down = str(Genome[SJ_chrom][SJ_end-ME_len:SJ_end]).upper()
                
                if strand=="-":
                    SJ_seq_up = str(Genome[SJ_chrom][SJ_end-ME_len:SJ_end].reverse_complement()).upper()
                    SJ_seq_down = str(Genome[SJ_chrom][SJ_start:SJ_start+ME_len].reverse_complement()).upper()
                    
                if SJ_start!=int(estart) and SJ_end!=int(eend):
                
                    SJ_end_seqs.add(SJ_seq_up)
                    SJ_end_seqs.add(SJ_seq_down)


            if sum_ME_SJ_coverage_up+sum_ME_SJ_coverage_down>0 and row["ME_type"]=="RESCUED":

                abs_up_down_diff = abs(sum_ME_SJ_coverage_up-sum_ME_SJ_coverage_down)/(sum_ME_SJ_coverage_up+sum_ME_SJ_coverage_down)

                if (len(estart_exons[(chrom, strand, estart)]) + len(eend_exons[(chrom, strand, eend)]) > 2) and abs_up_down_diff > 0.95:

                    #ME_black_list.write(row["ME"]+"\n")
                    pass

                elif row["micro_exon_seq_found"] in SJ_end_seqs:
                    ambiguous.write("\t".join([row["ME"], row["transcript"], row["sum_total_coverage"], row["total_SJs"], row["total_coverages"], row["len_micro_exon_seq_found"], row["micro_exon_seq_found"], row["total_number_of_micro_exons_matches"], row["U2_scores"], row["mean_conservations_vertebrates"], row["P_MEs"], row["total_ME"], row["ME_P_value"], row["ME_type"] ]) + "\n" )
                else:
                    print(row["ME"], row["transcript"], row["sum_total_coverage"], row["total_SJs"], row["total_coverages"], row["len_micro_exon_seq_found"], row["micro_exon_seq_found"], row["total_number_of_micro_exons_matches"], row["U2_scores"], row["mean_conservations_vertebrates"], row["P_MEs"], row["total_ME"], row["ME_P_value"], row["ME_type"], sep="\t")


if __name__ == '__main__':
    Genomictabulator(snakemake.input["genome"])
    main(snakemake.input["transcriptome"], snakemake.input["out_filtered"], snakemake.input["out_low_scored"], snakemake.input["PSI_files"])
