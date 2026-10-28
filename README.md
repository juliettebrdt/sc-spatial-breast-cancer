# Mapping a breast tumour by combining single-cell and spatial transcriptomics

Integration of **scRNA-seq** (10x Chromium Flex, FFPE) and **Visium CytAssist** spatial transcriptomics from **the same tumour block**, to estimate the cell-type composition of every spot of the tissue section. The analysis is explored in notebooks and being turned into a reproducible **Nextflow** pipeline.

![H&E section, tumour and myoepithelial cell proportions estimated by RCTD](notebooks/figures/03_tumour_myoepithelial.png)

**Key result.** Using the annotated single-cell data as a reference, RCTD deconvolution places tumour cells where the histology shows tumour, and recovers the feature that distinguishes in situ from invasive carcinoma: both DCIS regions combine tumour and myoepithelial cells (22 % and 11 % myoepithelial on average), whereas the invasive region is 87 % tumour with no myoepithelial signal. The single-cell annotation, the spatial domains and the deconvolution, three different methods, agree.

## Question

Visium spots are 55 µm wide and usually contain 5 to 20 cells, so each spot measures a mixture. Using single-cell data from the same tissue as a reference, can we locate **tumour cells, stroma and immune cells** on the section, and relate **spatial domains** to their cellular composition?

## Data

Public data from Janesick et al., *High resolution mapping of the tumor microenvironment using integrated single-cell, spatial and in situ analysis*, Nature Communications 2023 (GEO GSE243280): one FFPE HER2+ breast cancer block profiled on adjacent sections.

| dataset | technology | size |
|---|---|---|
| single-cell | Chromium Flex (probe-based, fixed RNA) | 30,365 cells × 18,082 genes |
| spatial | Visium CytAssist (FFPE) | 4,992 spots × 18,085 genes, with H&E image |
| labels | cell and spot annotations published by 10x | used only to check the analysis |

Both technologies use the same human probe panel, so all 18,082 single-cell genes are also measured in the spatial data.

## Approach

| notebook | step | tools |
|---|---|---|
| [`01_single_cell`](notebooks/01_single_cell.ipynb) | QC, doublets, clustering, marker-based annotation, comparison with published labels | Scanpy, Scrublet |
| [`02_visium`](notebooks/02_visium.ipynb) | spot QC, spatial domains, spatially variable genes (Moran's I), comparison with published domains | Squidpy, Scanpy |
| [`03_deconvolution`](notebooks/03_deconvolution.ipynb) | proportion of each cell type in each spot, checked against histology and domains | R spacexr (RCTD), in Docker |

The same steps are being turned into a Nextflow pipeline (in development), with each step in its own Docker container:

```
QC_SC ──> ANNOTATE_SC ──┐
                        ├──> DECONVOLVE_RCTD ──> REPORT
QC_SPATIAL ─────────────┘
```

## Running the notebooks

```bash
# 1. Environment (WSL2/Ubuntu or Linux, no root access needed):
#    Miniforge, then the "scspatial-python" conda environment from envs/python.yml
bash scripts/setup_wsl.sh

# 2. Data (~170 MB) into data/
bash scripts/download_data.sh

# 3. Docker image with R and RCTD, used by notebook 03 (20-40 minutes, once)
docker build -t scspatial-rctd:0.1 -f docker/rctd/Dockerfile .
```

Then run the notebooks in order with the `scspatial-python` kernel: each one reads the object saved by the previous one. About 10 GB of RAM are needed (Scrublet and RCTD are the most demanding steps).

## Results

### 1. Single-cell quality control and annotation

![Single-cell UMAP coloured by cluster and by annotated cell type](notebooks/figures/01_umap_cell_types.png)

- **QC thresholds chosen from the data**: ≥ 300 detected genes and ≤ 15 % mitochondrial counts. A 10 % cut-off was rejected after checking which cells it removed: invasive tumour cells have a higher baseline mitochondrial fraction (median 3.9 % vs 1.1-1.4 % for T cells, macrophages and stroma), and those between 10 and 15 % have *more* detected genes than the others, a sign of active rather than damaged cells.
- **Doublets**: Scrublet's automatic threshold would have removed 22 % of the cells (the score distribution has no second mode). A conservative threshold (0.18, 2.4 % of cells) was combined with a cluster-level review: three clusters (2,413 cells) were flagged as doublets from their median doublet score, their overlap with the hybrid cells annotated by 10x, and their two-cell-type marker profiles. One of them (fibroblast + tumour) has no equivalent category in the published labels.
- **Annotation**: 23 Leiden clusters annotated with a curated marker list ([`assets/MARKERS.md`](assets/MARKERS.md)) into 11 cell types, including two dendritic cell populations (plasmacytoid and LAMP3+) and plasma cells, which the published labels group with B cells. Tumour clusters carry the co-expression signature of the **ERBB2 (HER2) amplicon** on chromosome 17.
- **Agreement with the published labels**: 80-100 % per label; differences are mainly in granularity (CD4/CD8 T cells, DCIS vs invasive tumour are not separated).

### 2. Spatial domains

- **Spot QC**: a 500-molecule threshold removes 11 of 4,992 spots, mostly a row along the top edge of the capture area (technical artefact); poorer spots elsewhere follow fat and loose stroma and are kept.
- **17 spatial domains** (Leiden, resolution 0.8) form continuous regions that follow the H&E structures, although spot positions are not used by the clustering. A domain that looked scattered turned out to be an immune infiltrate (T cells, antigen-presenting cells, plasma cells) outlining the tumour ducts.
- **Spatially variable genes** (Moran's I up to 0.84) draw the main compartments: adipose tissue (FABP4, PLIN1), stroma (COL1A2), the invasive region (CDH2, HMGCS2) and the ducts.
- **The three tumour domains described in the article are recovered** without using it: DCIS #1 (two domains: duct centre and periphery), DCIS #2 (found at two distant places on the section) and the invasive region.

### 3. Cell-type deconvolution (RCTD)

![Mean cell-type proportions in each spatial domain](notebooks/figures/03_composition_by_domain.png)

- **Tumour cells**: 87 % of the invasive domain, 51-66 % of the DCIS domains, ≤ 3 % of the other domains.
- **Myoepithelial cells**: 22 % (DCIS #1) and 11 % (DCIS #2) on average, highest at the duct-stroma interface (31 %) and at the periphery of DCIS #1, and **absent from the invasive domain**, consistent with tumour cells having crossed the myoepithelial layer.
- **Immune cells**: T cells are enriched in the immune domain around the ducts (24 % in the published immune domain) and always mixed with stroma at the 55 µm spot scale.
- Each spatial domain has the composition its marker genes suggested (vessels, stroma with B cells, plasma cell-rich stroma…).

## Limitations

- Annotation relies on a marker list with one tumour type: DCIS and invasive tumour cells are not distinguished in the single-cell data, and perivascular cells are merged with endothelial cells.
- The reference contains no adipocytes (they do not survive dissociation), so adipose spots are explained as fibroblasts, endothelial cells and macrophages.
- RCTD proportions describe RNA content rather than cell numbers, and the one-cell-thick myoepithelial layer is much thinner than a spot.
- The published labels helped select the markers, so the comparison with these labels is not fully independent.
- A single sample; the analysis starts from the Cell Ranger / Space Ranger count matrices (no FASTQ processing).
- Next steps: the Nextflow pipeline; Xenium in situ data from the same block (single-cell resolution); copy-number inference to separate tumour from normal epithelial cells.

## Environment

Python 3.11 (Scanpy 1.11, Squidpy 1.8), see `envs/python.yml`. R 4.4 with spacexr, in Docker (`docker/rctd/Dockerfile`). Tested on Windows 11 with WSL2 (Ubuntu).

## References

- Janesick A. et al. High resolution mapping of the tumor microenvironment using integrated single-cell, spatial and in situ analysis. *Nat Commun* 2023.
- Wolf F.A., Angerer P., Theis F.J. SCANPY: large-scale single-cell gene expression data analysis. *Genome Biol* 2018.
- Palla G. et al. Squidpy: a scalable framework for spatial omics analysis. *Nat Methods* 2022.
- Wolock S.L., Lopez R., Klein A.M. Scrublet: computational identification of cell doublets in single-cell transcriptomic data. *Cell Syst* 2019.
- Cable D.M. et al. Robust decomposition of cell type mixtures in spatial transcriptomics. *Nat Biotechnol* 2022.
- Di Tommaso P. et al. Nextflow enables reproducible computational workflows. *Nat Biotechnol* 2017.
- Wu S.Z. et al. A single-cell and spatially resolved atlas of human breast cancers. *Nat Genet* 2021.
