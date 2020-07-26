#!/bin/sh
while true
do
	bcldir="/550AR/"
	outdir="/nfs/NGS_project/"
	donedir="/nfs/NGS_project/batchdone"
	logsdir="/nfs/NGS_project/logs"
	bcl2fastqpath="/nfs/software/bin/bcl2fastq"
	workflowpath="/nfs/database/ngs_pipeline/snakefile-ngs-V1/"

	for i in `ls -d ${bcldir}/*`;do
		runid=`basename ${i}`
		if [ ! -f "${donedir}/${runid}.done" ];then
			if [ -f "${i}/SampleSheet.csv" ];then
				echo -e "
#!/bin/sh
#PBS -N ${runid}-allsetp
#PBS -l nodes=3:ppn=30
#PBS -o ${logsdir}/${runid}.out
#PBS -e ${logsdir}/${runid}.err
#PBS -l walltime=120:00:00

echo $(data +%F%n%T)
#${bcl2fastqpath} -i ${bcldir}/${runid}/Data/Intensities/BaseCalls/ --interop-dir ${bcldir}/${runid}/InterOp/ -R ${bcldir}/${runid} --stat-dir ${bcldir}/${runid}/Stats/ --sample-sheet  ${bcldir}/${runid}/SampleSheet.csv --barcode-mismatches 0 --no-lane-splitting -o ${outdir}/${runid}
${bcl2fastqpath} -R ${bcldir}/${runid} -o ${outdir}/${runid} --sample-sheet ${bcldir}/${runid}/SampleSheet.csv --barcode-mismatches 0 --no-lane-splitting
echo $(data +%F%n%T)
python3 ${workflowpath}/run_workflow.py -W ${outdir}/${runid}_workdir -I ${outdir}/${runid}/CNS/ -O ${outdir}/${runid}_result -R ${outdir}/${runid}_report --workflow ${workflowpath} --samplesheet ${bcldir}/${runid}/SampleSheet.csv
echo $(data +%F%n%T)
snakemake --cores 72 --snakefile ${workflowpath}/Snakefile --restart-times 1 --rerun-incomplete --configfile ${outdir}/${runid}_workdir/config.yaml
echo $(data +%F%n%T)  >${logsdir}/${runid}.pbs

				sleep 10
				cd ${logsdir} && chmod 755 ${logsdir}/${runid}.pbs && qsub ${logsdir}/${runid}.pbs;
				sleep 60 
				while [ ! -z "`qstat`" ]
				do
					sleep 20 !
				done &&
				touch ${donedir}/${runid}.done

				rsync -acqzP ${outdir}/${runid}_report ngsdata@172.16.157.66:/gpfsdata/home/ngsdata/SY/ &&
			fi
			else:
				sleep 10m
		fi
	done
done

