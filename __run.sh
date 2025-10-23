

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
  -stub \
  --assembly.short_unicycler=true \
  --assembly.short_spades=true \
  --assembly.hybrid_flye_medaka_pilon=true \
  --samplesheet=data/samplesheet.csv



# Merge dev branch with master branch
git checkout dev
git merge master
git checkout master
git merge dev
git tag -a v0.4.13 -m "Fix and improve some assembly output"
git push origin --tags
git push origin
git checkout dev




ssh prados@bamboo

apptainer run 

