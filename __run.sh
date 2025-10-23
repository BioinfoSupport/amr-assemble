

# Get a bash to run nextflow
docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(pwd):$(pwd) \
  --platform linux/amd64 \
  --workdir $(pwd) \
  --env NXF_HOME=$(pwd)/.nextflow_home \
  nextflow/nextflow:25.10.0 bash

cd test
nextflow run . 

nextflow run . -profile docker,arm64 -stub --samplesheet=data/samplesheet.csv
nextflow run . -profile docker,arm64 \
  --assembly.long_hybracter=true \
  --assembly.long_unicycler=true \
  --assembly.long_flye_medaka=true \
  --assembly.short_unicycler=true \
  --assembly.short_spades=true \
  --assembly.hybrid_flye_medaka_pilon=true \  
  --assembly.hybrid_hybracter=true \
	--assembly.hybrid_hybracter=true \
  --samplesheet=data/samplesheet.csv


# Merge dev branch with master branch
git checkout dev
git merge master
git checkout master
git merge dev
git tag -a v0.1-beta2 -m "First beta release of the assembly pipeline"
git push origin --tags
git push origin
git checkout dev



# Test on HPC
rsync -av data prados@bamboo:~/scratch/test_asm/
ssh prados@bamboo
cd ~/scratch/test_asm
nextflow run BioinfoSupport/amr-assemble -r v0.1-beta -profile hpc --samplesheet=data/samplesheet.csv





