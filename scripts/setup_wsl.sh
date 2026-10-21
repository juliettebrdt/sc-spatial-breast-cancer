#!/usr/bin/env bash
# Install the project environment on WSL2 (Ubuntu), without sudo.
#   1. Miniforge (conda + mamba) in ~/miniforge3
#   2. Java 17 + Nextflow in the conda "base" environment (always active)
#   3. The Python environment of the notebooks: envs/python.yml -> scspatial-python
# Usage (from the repository root): bash scripts/setup_wsl.sh
set -euo pipefail

CONDA_DIR="$HOME/miniforge3"

if [ ! -x "$CONDA_DIR/bin/conda" ]; then
  echo ">> Installing Miniforge"
  curl -L -o /tmp/Miniforge3.sh \
    "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"
  bash /tmp/Miniforge3.sh -b -p "$CONDA_DIR"   # -b: batch mode, no questions
  rm /tmp/Miniforge3.sh
  "$CONDA_DIR/bin/conda" init bash               # activate conda in every new terminal
fi

# Make conda/mamba usable inside this script
source "$CONDA_DIR/etc/profile.d/conda.sh"

echo ">> Java 17 + Nextflow (base environment)"
mamba install -y -n base -c conda-forge -c bioconda openjdk=17 "nextflow>=24.04"

echo ">> Project Python environment (10 to 20 minutes)"
if conda env list | grep -q "^scspatial-python "; then
  mamba env update -n scspatial-python -f envs/python.yml
else
  mamba env create -f envs/python.yml
fi

echo ">> Checks"
conda activate base
java -version
nextflow -version
conda run -n scspatial-python python -c "import scanpy, squidpy; print('scanpy', scanpy.__version__, '| squidpy', squidpy.__version__)"
echo ">> Done. Open a new terminal so that 'conda activate' works."
