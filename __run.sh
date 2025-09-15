

# Get a bash to run nextflow
docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(pwd):$(pwd) \
  --platform linux/amd64 \
  --workdir $(pwd) \
  --env NXF_HOME=$(pwd)/.nextflow_home \
  nextflow/nextflow:25.04.6 bash

nextflow run . -profile standard,arm64 --samplesheet=data/samplesheet.csv


# Merge dev branch with master branch
git checkout dev
git merge master
git checkout master
git merge dev
git tag -a v0.4.13 -m "Fix and improve some assembly output"
git push origin --tags
git push origin
git checkout dev




