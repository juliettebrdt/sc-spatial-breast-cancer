#!/usr/bin/env bash
# Download the public data of Janesick et al. (Nat Commun 2023) into data/
# Usage: bash scripts/download_data.sh
set -euo pipefail

mkdir -p data/chromium data/visium data/annotations

echo ">> Single-cell Chromium Flex (FFPE), filtered count matrix"
curl -L -o data/chromium/filtered_feature_bc_matrix.h5 \
  "https://cf.10xgenomics.com/samples/cell-exp/7.0.1/Chromium_FFPE_Human_Breast_Cancer_Chromium_FFPE_Human_Breast_Cancer/Chromium_FFPE_Human_Breast_Cancer_Chromium_FFPE_Human_Breast_Cancer_count_sample_filtered_feature_bc_matrix.h5"

echo ">> Visium CytAssist: filtered count matrix + spatial folder (H&E image, spot positions)"
curl -L -o data/visium/filtered_feature_bc_matrix.h5 \
  "https://cf.10xgenomics.com/samples/spatial-exp/2.0.0/CytAssist_FFPE_Human_Breast_Cancer/CytAssist_FFPE_Human_Breast_Cancer_filtered_feature_bc_matrix.h5"
curl -L -o data/visium/spatial.tar.gz \
  "https://cf.10xgenomics.com/samples/spatial-exp/2.0.0/CytAssist_FFPE_Human_Breast_Cancer/CytAssist_FFPE_Human_Breast_Cancer_spatial.tar.gz"
tar -xzf data/visium/spatial.tar.gz -C data/visium && rm data/visium/spatial.tar.gz

echo ">> Cell annotations published by 10x (sheet 'scFFPE-Seq' = single-cell labels)"
curl -L -o data/annotations/Cell_Barcode_Type_Matrices.xlsx \
  "https://cdn.10xgenomics.com/raw/upload/v1695234604/Xenium%20Preview%20Data/Cell_Barcode_Type_Matrices.xlsx"

echo ">> Done. Contents:"
find data -maxdepth 2 | sort
# If a link stops working, see the dataset page:
# https://www.10xgenomics.com/products/xenium-in-situ/preview-dataset-human-breast
# or GEO GSE243280
