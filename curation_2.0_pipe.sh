#!/bin/sh 

Help()
{
    # Display help

    printf "\nCommand: sh curation_2.0_pipe.sh -f <original fasta> -a <agp> <options>\n\n"
    echo "-h Prints help."
    echo "-f Pass original fasta file with combined haplotypes."
    echo "-a Pass the agp generated by PretextView."
    echo "-p Pass the primary assembly you curated (1 for haplotype 1 (default), 2 for haplotype 2)."
    printf "\n"
}

fasta=""
agpfile=""
hap=""

while getopts ":hf:a:p:" option; do
    case $option in 
        h) #display Help
            Help
            exit;;
        f) #Pass original fasta file 
            fasta=$OPTARG;;
        a) #Pass Pretext generated AGP file of curated assembly
            agpfile=$OPTARG;;
        p) #Pass haplotype of interest ()
            hap="$OPTARG";;
    esac
done

mkdir -p logs 
count=`ls logs/* | wc -l`
exec 1<> logs/std.${count}.out

## Programs/tools
use_gfastats=/vggpfs/fs3/vgl/store/nbrajuka/gfastats/build/bin/gfastats
use_seqkit=/vggpfs/fs3/vgl/store/nbrajuka/conda/envs/statistics/bin/seqkit
#use_vsearch=/vggpfs/fs3/vgl/store/nbrajuka/conda/envs/curation/bin/vsearch
printf "Dependecies:\nBiopython v1.81\n" 
$use_gfastats -v 
pth=/lustre/fs5/vgl/store/nbrajuka/curation_scripts/curation2

printf "\nOriginal assembly: ${fasta} \nPretextView generated AGP: ${agpfile}\n\n" ### but checks/breakpoints for if these aren't provided.

echo "python3 ${pth}/AGPcorrect.py ${fasta} ${agpfile}"
python3 $pth/AGPcorrect.py ${fasta} ${agpfile} 


mkdir -p Hap_1
mkdir -p Hap_2

python3 $pth/hap_split.py 

python3 $pth/unloc.py Hap_1
python3 $pth/unloc.py Hap_2


# if [ ${hap} -eq 1 ]
# then
#     # outdir=./Hap_1/
#     # mkdir $outdir

#     printf "\nSplitting haplotype ${hap} from corrected.agp.\n\n" 

#     echo "grep -E '#|Painted|proximity_ligation|H1' corrected.agp > hap.agp"
#     grep -E '#|Painted|proximity_ligation|H1' corrected.agp > hap.agp 

#     python3 $pth/unloc.py
#     # mv hap.unlocs.no_hapdups.agp ${outdir}/
# elif [ ${hap} -eq 2 ]
# then
#     # outdir=./Hap_1/
#     # mkdir $outdir

#     printf "\nSplitting haplotype ${hap} from corrected.agp.\n\n" 

#     echo "grep -E '#|Painted|proximity_ligation|H2' corrected.agp > hap.agp"
#     grep -E '#|Painted|proximity_ligation|H2' corrected.agp > hap.agp 

#     printf "\nModifying the AGP to account for unlocalized sequences.\n\n"
#     python3 $pth/unloc.py
#     # mv hap.unlocs.no_hapdups.agp ${outdir}/
# fi

printf "${use_gfastats} $fasta --agp-to-path Hap_1/hap.unlocs.no_hapdups.agp --sort largest -o Hap_1/hap.sorted.fa\n"
${use_gfastats} $fasta --agp-to-path Hap_1/hap.unlocs.no_hapdups.agp --sort largest -o Hap_1/hap.sorted.fa 2>> logs/std.${count}.out 

printf "${use_gfastats} $fasta --agp-to-path Hap_1/hap.unlocs.no_hapdups.agp --sort largest -o Hap_1/hap.sorted.fa\n"
${use_gfastats} $fasta --agp-to-path Hap_2/hap.unlocs.no_hapdups.agp --sort largest -o Hap_2/hap.sorted.fa 2>> logs/std.${count}.out 


printf "python3 $pth/chromosome_assignment.py Hap_1"
python3 $pth/chromosome_assignment.py Hap_1

printf "python3 $pth/chromosome_assignment.py Hap_2"
python3 $pth/chromosome_assignment.py Hap_2 

# mv int_chr.tsv ${outdir}/
# mv hap.chr_level.fa ${outdir}/

exec 1>&-

