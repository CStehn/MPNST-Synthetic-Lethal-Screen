# Synthetic Lethal CRISPR Screening Analysis

## Overview

This repository contains the end-to-end analysis pipeline for genome-wide CRISPR/Cas9 synthetic-lethal fitness screens in MPNST (malignant peripheral nerve sheath tumor) and iPN-derived (induced pluripotent Schwann) cell line models, using the Broad GPP **Brunello** lentiviral sgRNA library.

The workflow covers three stages:

1. **Read count quantification** - trimming raw FASTQ reads and counting sgRNA representation with `cutadapt` + `MAGeCK count`
2. **Fold-change generation** - gene-level depletion/enrichment estimates with `MAGeCK mle` (median-normalized log2 fold changes)
3. **Chronos gene effect scores** - batch-aware gene fitness scoring with the `Chronos` model (`chronos_calc.py`, `chronos_calc_w_achilles.py`)

## Cell Line Screens

| Cohort | Cell lines | Timepoints | Scripts |
|---|---|---|---|
| MPNSTs | ST88-14, STS-26T | pDNA (initial) / final (day 18) | `MAGeCK_count_MPNST.sh`, `MAGeCK_mle_MPNST.sh` |
| iPNs | iPN1L, iPN2J, iPN3D | initial / middle / final | `MAGeCK_count_iPN.sh`, `MAGeCK_mle_iPN.sh` |
| run3 / run3redux | iHSC1L-A4, iHSC1L-C3, iHSC1L-F12, S462-E9 | pDNA (initial) / final (day 18) | `cutadapt_brunello.sh`, `mageck_count_run3redux.sh`, `mageck_mle_run3.sh` |

## Reference Files

| File | Description |
|---|---|
| `broadgpp-brunello-library-corrected.txt` | Brunello library definition (sgRNA sequences, genomic coordinates, target genes) |
| `broadgpp-brunello-controls.txt` | Non-targeting control sgRNAs (negative controls) |
| `sgrna_map.txt` | sgRNA-to-gene mapping used by Chronos |
| `AchillesCommonEssentials.csv` | Achilles common essential genes (positive controls) |
| `adapter_list.tsv` | Adapter sequences; `TTGTGGAAAGGACGAAACACCG` is the lentiGuide-Puro 5' constant region used for trimming |

## Environment

- Conda environment defined in `mageckenv.yml` (MAGeCK 0.5.9.5, Python 3.10)
- Separate `chronos` conda environment for the Chronos dependency (activated in `chronos_calc.sh`)
- SLURM batch scripts; submit with e.g. `sbatch MAGeCK_count_MPNST.sh`

---

## 1. Adapter Trimming

`run3/cutadapt_brunello.sh` and `run3redux/cutadapt_brunello.sh` trim the 5' constant sgRNA backbone (derived from the Brunello lentiGuide-puro plasmid, Addgene #52963) from each R1 FASTQ to improve MAGeCK counting efficiency:

```bash
cutadapt -g TTGTGGAAAGGACGAAACACCG -j 0 -o ${OUT}/${SAMP}.fastq.gz ${CURFQ}
```

Trimmed FASTQs are written to `run3/trimmed_fastq/` and `run3redux/trimmed_fastq/`. Trimming summaries are logged in `run3(run|redux)_trimming.out`.

## 2. Read Count Quantification (`MAGeCK count`)

Counts raw (MPNSTs, iPNs) or trimmed (run3/run3redux) reads against the Brunello library, with median normalization and non-targeting controls:

```bash
mageck count \
    -l broadgpp-brunello-library-corrected.txt \
    --fastq ${FASTQ}/*R1_001.fastq.gz \
    --control-sgrna broadgpp-brunello-controls.txt \
    --sample-label <SAMPLE,LABELS,HERE> \
    --norm-method median \
    --pdf-report \
    --keep-tmp \
    -n <PREFIX>
```

Outputs land in each cohort's `counts/` directory:

| Cohort | Output directory | Key files |
|---|---|---|
| MPNSTs | `MPNSTs/counts/` | `MPNST.count.txt`, `MPNST.count_normalized.txt`, `MPNST.countsummary.txt`, `MPNST_design.txt` |
| iPNs | `iPNs/counts/` | `synthetic_lethal.count.txt`, `synthetic_lethal.count_normalized.txt`, `synthetic_lethal.countsummary.txt` |
| run3 | `run3/counts/` (run3redux variant in `run3redux/counts/`) | `run3(.redux).count.txt`, `run3(.redux).count_normalized.txt`, countsummary `.Rnw` reports |

Per-cell-line QC reports (Rnw/Rmd/PDF `*_summary` files) are generated alongside the count tables.

### Combined count matrices

Per-cohort count tables are merged into project-wide matrices used as Chronos input:

- `all_counts.txt` / `all_counts_sub.txt` - merged raw sgRNA counts for all screen cohorts (columns are `sequence_ID`s)
- `all_counts_w_achilles.txt` - as above, plus the Achilles external control datasets (batch BR-13/BR-15)

### Sample annotation

Chronos sample maps, paired with the count matrices by `sequence_ID`:

- `all_samples.txt` / `all_samples_sub.txt` / `all_samples_w_achilles.txt`

with columns:

| Column | Meaning |
|---|---|
| `sequence_ID` | Sample identifier matching the count matrix column header |
| `cell_line_name` | Cell line the sample belongs to; `pDNA` denotes plasmid DNA (day 0) samples |
| `pDNA_batch` | Screening batch; each initial/pDNA sample is paired with its timepoint sample from the same batch |
| `days` | Time since transduction |

## 3. Gene-Level Fold Changes (`MAGeCK mle`)

Fit a linear model against sample design matrices to produce median-normalized log2 fold changes per guide and gene, relative to pDNA baseline:

```bash
mageck mle \
    -k ${COUNTS}/<PREFIX>.count.txt \
    -d <PREFIX>_design.txt \
    -n <PREFIX>_mle
```

Outputs land in each cohort's `essentiality/` directory:

| Cohort | Output directory | Key files |
|---|---|---|
| MPNSTs | `MPNSTs/essentiality/` | `MPNST_mle.gene_summary.txt`, `MPNST_mle.sgrna_summary.txt` |
| iPNs | `iPNs/essentiality/` | `synthetic_lethal.gene_summary.txt`, `synthetic_lethal.sgrna_summary.txt` |
| run3 | `run3/essentiality/` (run3redux variant in `run3redux/essentiality/`) | `run3_mle.gene_summary.txt`, `run3_mle.sgrna_summary.txt` |

Each `-d` design file (e.g. `MPNSTs/counts/MPNST_design.txt`, `run3/run3.design.txt`) encodes pDNA initialization samples as the baseline (`1`) and flags each cell line's final/middle timepoint samples (`1` per model column).

## 4. Chronos Gene Effect Scores

### Scripts

| Script | Input count matrix | Output |
|---|---|---|
| `chronos_calc.py` | `all_counts_sub.txt` + `all_samples_sub.txt` | `chronos_output/`, `gene_effects.csv` |
| `chronos_calc_w_achilles.py` | `all_counts_w_achilles.txt` + `all_samples_w_achilles.txt` | `chronos_output_w_achilles/`, `gene_effects_w_achilles.csv` |

`chronos_calc_w_achilles.py` additionally co-models the Achilles external reference datasets (Meljuso / OVCAR8 / A375 / HAP1 pilot drug-dropout experiments and their pDNA batches), which can improve batch correction and guide-efficacy estimation.

`chronos_calc.sh` is the SLURM wrapper (`chronos` env, 8 tasks, 40 GB, 8 h) that runs `chronos_calc_w_achilles.py`.

### Inputs

Count matrices (`all_counts*.txt`), sample annotation (`all_samples*.txt`), sgRNA-to-gene map (`sgrna_map.txt`), and sgRNA targets in `broadgpp-brunello-controls.txt` (negative) and `AchillesCommonEssentials.csv` (positive) are read in `chronos_calc*.py`.

### Workflow

```python
readcounts = pd.read_table(wd + counts, index_col = [0]).drop("gene", axis = 1).T
sequence_map = pd.read_table(wd + samples)
guide_map = pd.read_table(wd + mapping)
common_essentials = pd.read_csv(wd + positive, header = None)
with open(wd + negative, 'r') as file:
    ctrl = [line.rstrip('\n') for line in file]
neg_ctrl = guide_map.sgrna[guide_map.sgrna.isin(ctrl)]
pos_ctrl = guide_map.sgrna[guide_map.gene.isin(common_essentials)]

chronos.normalize_readcounts(readcounts, neg_ctrl, sequence_map)
chronos.nan_outgrowths(readcounts, sequence_map, guide_map)

model = chronos.Chronos(
        readcounts={'syn_lethal': readcounts},
        sequence_map={'syn_lethal': sequence_map},
        guide_gene_map={'syn_lethal': guide_map},
        negative_control_sgrnas={'syn_lethal': neg_ctrl}
        )

model.train()
model.save(wd + "chronos_output")
gene_effect = model.gene_effect
gene_effect -= gene_effect.reindex(columns=neg_ctrl).median(axis=1).median()

gene_effect.to_csv(wd + "chronos_scores.csv")
```

1. **Normalize** read counts relative to non-targeting controls using `chronos.normalize_readcounts`
2. **Nan out** outgrowth timepoints using `chronos.nan_outgrowths`
3. **Fit** the Chronos model (`model.train()`, `model.save(...)`) with `readcounts`, `sequence_map`, `guide_gene_map`, and `negative_control_sgrnas`
4. **Correct** gene effect scores by subtracting the median effect across non-targeting control guides
5. **Write** gene effects to `gene_effects*.csv`

### Outputs

`chronos_output/` (and `chronos_output_w_achilles/`) contains trained model artifacts:

| File | Description |
|---|---|
| `gene_effect.hdf5` | Per-gene, per-cell-line effect scores (final gene effects, after control-guide correction) |
| `growth_rate.csv` | Estimated per-replicate growth rates (e.g. `S462_batch6_E12_S462_E9_Final, syn_lethal, 1.381`) |
| `library_effect.csv` | Estimated per-guide library effect |
| `guide_efficacy.csv` | Estimated per-guide knockout efficacy |
| `t0_offset.csv` | Estimated day-0 read count offset per pDNA batch |
| `screen_delay.csv`, `screen_excess_variance.csv` | Timing / variance parameters per screen |
| `replicate_efficacy.csv` | Kill-rate agreement across replicate comparisons |
| `*_predicted_lfc.hdf5`, `*_predicted_readcounts.hdf5` | Model-predicted read counts / log fold changes |

`gene_effects.csv` columns are per-cell-line Chronos scores (e.g. `S462, ST88-14, STS-26T, iHSC1L_C3, iHSC1L_F12, iPN1L, iPN2J, iPN3D`). More-negative values indicate stronger gene dependency (depletion).
