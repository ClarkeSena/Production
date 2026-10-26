#!/usr/bin/bash
# Generate fcl files for BeamTo2VD<line>.fcl (line = 347, 844 or 1809), i.e. a monoenergetic photon
# line generated from the muon target stops and propagated to VD101 and VD116.
# Generalisation of gen_BeamToVD1809.sh to the other Al lines.
# Generates fcl files in directories <line>_00X and stores the seeds in BeamTo2VD<line>Seeds

# $1 is the production (ie MDC2025)
# $2 is the input production version (TargetStopsCat)
# $3 is the output production version
# $4 is the number of events per job
# $5 is the number of jobs
# $6 is the line: 347, 844 or 1809
# $7 is the run number (use a distinct one per line so the datasets cannot collide)

# Validate the number of arguments
if [[ ${7} == "" ]]; then
  echo "Missing arguments!"
  echo "Usage: $0 <production> <input version> <output version> <events/job> <njobs> <347|844|1809> <run>"
  exit 1
fi
line=$6
case $line in
  347|844|1809) ;;
  *) echo "Unknown line $line, expected 347, 844 or 1809"; exit 1 ;;
esac
desc=BeamTo2VD${line}

# Generate a list of all the staged TargetStopsCat files and count the events
muStopDataset=sim.mu2e.TargetStopsCat.$1$2.art
rm -f TargetStopsCat.txt
samweb list-file-locations --schema=root --defname="$muStopDataset"  | cut -f1 > TargetStopsCat.txt
nFiles=`samCountFiles.sh $muStopDataset`
nEvts=`samCountEvents.sh $muStopDataset`
nSkip=$((nEvts/nFiles))
echo "Target stops: found $nEvts events in $nFiles files, skipping max of $nSkip events per job"

# Write the base propagation script
rm -f tmp.fcl
echo "#include \"Production/JobConfig/pileup/STM/${desc}.fcl\"" >> tmp.fcl
echo physics.filters.TargetStopResampler.mu2e.MaxEventsToSkip: ${nSkip} >> tmp.fcl

# Generate the fcl files
generate_fcl --dsconf=$1$3 --dsowner=$USER --run-number=$7 --description=${desc} --events-per-job=$4 --njobs=$5 \
  --embed tmp.fcl --auxinput=1:physics.filters.TargetStopResampler.fileNames:TargetStopsCat.txt

# Write the files to the correct directories
for dirname in 000 001 002 003 004 005 006 007 008 009; do
 if test -d $dirname; then
  rm -rf ${line}_$dirname
  mv $dirname ${line}_$dirname
 fi
done

# Save the seed file to a directory
seedDir="${desc}Seeds"
mkdir -p $seedDir
mv seeds.$USER.${desc}.$1$3.*.txt $seedDir

# Cleanup
echo "Removing produced files"
rm -f tmp.fcl
rm -f TargetStopsCat.txt
echo "Finished"
