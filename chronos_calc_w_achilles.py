import chronos
import pandas as pd

wd = "/projects/standard/largaesp/shared/synthetic_lethal/"
counts = "all_counts_w_achilles.txt"
samples = "all_samples_w_achilles.txt"
mapping = "sgrna_map.txt"
negative = "broadgpp-brunello-controls.txt"
positive = "AchillesCommonEssentials.csv"

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
model.save(wd + "chronos_output_w_achilles")
gene_effect = model.gene_effect
gene_effect -= gene_effect.reindex(columns=neg_ctrl).median(axix=1).median()

gene_effect.to_csv(wd + "chronos_scores_w_achilles.csv")
