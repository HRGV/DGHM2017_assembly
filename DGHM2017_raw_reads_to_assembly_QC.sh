#/bin/sh
#create working directory
mkdir DGHM_2017_test2
#move to working directory
cd DGHM_2017_test2/
#Download read set from ebi sra - read 1 and read 2 necessary as they are paired end
for n in 1 2; do wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/DRR076/DRR076717/DRR076717_${n}.fastq.gz; done
#run read level qualtiy control
#fix - download fastqc and call from dl file!
#for n in *fastq.gz; do fastqc $n; done FIX
#run kaiju for taxonomic composition screening
kaiju -f ~/save/kaiju_db.fmi -t ~/save/nodes.dmp -i <(zcat DRR076717_1.fastq.gz | head -n 400000) -j <(zcat DRR076717_2.fastq.gz | head -n 400000) -a greedy -e 5 -o DRR076717.100k.kaiju.out.txt
kaijuReport -n ~/save/names.dmp -t ~/save/nodes.dmp -i DRR076717.100k.kaiju.out.txt -o DRR076717.100k.kaiju.out.genus.txt -r genus -m .1
#optional - SSU based library quality and composition tests
#phyloFlash_latest -lib DRR076717 -read1 DRR076717_1.fastq.gz -read2 DRR076717_2.fastq.gz -readlength 150 -skip_spades -skip_emirge
#adapter trimming from the read end
bbduk.sh ref=/opt/bbmap/resources/adapters.fa interleaved=t ktrim=r trimq=2 qtrim=rl minlength=50 mink=11 hdist=1 in=DRR076717_1.fastq.gz in2=DRR076717_2.fastq.gz out=DRR076717_all_fr_ktrimr_q2.fq.gz overwrite=t reads=100000 #reads=-1 for all reads or remove switch completely
#run kmer count based ultra low coverage read removal
bbnorm.sh in=DRR076717_all_fr_ktrimr_q2.fq.gz interleaved=t hist=DRR076717_hist.txt peaks=DRR076717_peaks.txt -Xmx10g lowbindepth=1 highbindepth=3 outhigh=DRR076717_kmerfilt3_fr.fq.gz passes=1
#check the input files again using fastqc
#for n in *fq.gz; do fastqc $n; done # FIX
#run spades assembly on kmer filtered data
spades.py --12 DRR076717_kmerfilt3_fr.fq.gz -t 6 -m 20 -o DRR076717_kmerfilt3_SP310_default
#get assembly statistics
quast.py ./DRR076717_kmerfilt3_SP310_default/scaffolds.fasta -f
#map reads back to assembly to look for base coverage and generate coverage and GC data for visualization
bbmap.sh ref=./DRR076717_kmerfilt3_SP310_default/scaffolds.fasta in=DRR076717_1.fastq.gz in2=DRR076717_2.fastq.gz fast=t covstats=DRR076717_to_DRR076717_kmerfilt3_SP310_default.txt threads=6
