# Marker genes (`markers_breast.csv`)

Used by `bin/annotate_sc.py` (and notebook 01) to name Leiden clusters: each cell gets a score per cell type (`sc.tl.score_genes`), and each cluster takes the type with the highest mean score. The same names become the cell types of the RCTD reference.

## How the list was built

1. **Candidates from the literature**: canonical markers of each population, cross-checked with
   - Wu et al. 2021, *Nature Genetics*, "A single-cell and spatially resolved atlas of human breast cancers" (breast tumour microenvironment);
   - Villani et al. 2017, *Science* (human dendritic cell subsets, including plasmacytoid DCs);
   - Cheng et al. 2021, *Cell* (pan-cancer atlas of tumour-infiltrating myeloid cells, including LAMP3+ DCs).
2. **Panel check**: Flex measures a probe panel of 18,082 genes. KRT18, TPSAB1 and TPSB2 are absent and were dropped.
3. **Check on the data**: after QC (≥ 300 genes, ≤ 15 % MT), each candidate was tested against the cell labels published by 10x for this sample (grouped into the types below; hybrids and unlabelled cells excluded). A gene was kept only if its mean log-normalised expression is **highest in the expected type**, and preferably at least ~3 times higher than in any other type.

The 10x labels were used only to *select* markers, not to annotate cells. Comparing the final annotation with the same labels is therefore not fully independent; this is noted in the README.

## Types and evidence

| type | markers | notes |
|---|---|---|
| Tumor_epithelial | EPCAM, KRT8, KRT19, CDH1, ELF3, CLDN4 | Generic epithelial markers: only 1.3-1.7× higher than in myoepithelial cells, which are also epithelial. Tumour and myoepithelial cells are told apart by the myoepithelial markers. Cannot separate DCIS from invasive tumour. |
| Myoepithelial | KRT5, KRT14, KRT17, TP63, KRT15 | KRT14, KRT17, TP63: > 10×. Removed: ACTA2 and MYLK (higher or similar in perivascular cells), CNN1 (weak). |
| Fibroblasts | COL1A1, DCN, LUM, PDGFRA, FBLN1 | DCN, LUM, FBLN1, PDGFRA: 4.6-6×. Collagens are also high in perivascular cells (1.7×), so only COL1A1 is kept. |
| Endothelial | VWF, CDH5, PLVAP, EMCN, CLDN5 | 4.6-9.4×. Removed: PECAM1 (only 2.1×, also in pDCs). |
| Perivascular | RGS5, NOTCH3, CSPG4, MCAM | 2-4.5×. Removed: MYH11 (higher in myoepithelial cells), PDGFRB (1.7×, also in fibroblasts). |
| T_cells | CD3D, CD3E, CD2, TRAC | 5.6-6.4×. Removed: CD8A (only a subset of T cells), IL7R (1.3×, also in LAMP3 DCs). |
| B_cells | MS4A1, CD79A, CD79B, CD19, BANK1 | 6-23×. Removed: CD22 (1.0×, also in mast cells). |
| Plasma_cells | JCHAIN, IGKC, IGHA1, MZB1, TNFRSF17 | No 10x label: checked on 194 putative plasma cells (10x "B Cells" that are MS4A1⁻ JCHAIN⁺ IGKC⁺). JCHAIN and MZB1 are also expressed by pDCs; IGKC and IGHA1 separate plasma cells from pDCs (3-5×). Immunoglobulin RNA is abundant and can leak into other cells as ambient RNA. |
| Plasmacytoid_DC | LILRA4, CLEC4C, PTCRA, IL3RA | 10x "IRF7+ DCs". LILRA4 and CLEC4C: > 50×. Removed: IRF7 (interferon response, broad), GZMB (cytotoxic cells). |
| LAMP3_DC | LAMP3, IDO1, CCR7, FSCN1 | 10x "LAMP3+ DCs" (mature, migratory DCs). LAMP3: 38×. Removed: CLEC9A and FCER1A (not expressed in this population). |
| Mast_cells | CPA3, MS4A2, HDC, KIT | 17-120×. |

## Changes from the first version

- `Dendritic_cells` split into **Plasmacytoid_DC** and **LAMP3_DC**: two unrelated populations, both present in this sample (210 and 103 cells in the 10x labels).
- Non-specific markers removed (listed above) and missing-from-panel genes dropped.

Limits: one tumour type only (no DCIS vs invasive markers), and markers checked on a single sample.
