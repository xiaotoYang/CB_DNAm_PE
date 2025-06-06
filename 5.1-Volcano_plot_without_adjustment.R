# Library:
library(lumi)
library(limma)
library(dplyr)
library(ggplot2)
library(ggrepel)

# Shortcut from 1 - Raw data pre-processing.Rmd
load("/home/liuwent/04-Full_Model/myLoad.Rdata")
load("/home/liuwent/04-Full_Model/Mvalues.RData")

## model2: regress only on sample group-----------------------------
myLoad$pd$Sample_Group = relevel(factor(myLoad$pd$Sample_Group), ref="Controls")
design0 = model.matrix(~myLoad$pd$Sample_Group)
fit0 = lmFit(beta2m(Mvalues), design0)
fit00 = eBayes(fit0)
save(fit00, file = "fit00.RData")

## Get log_2 fold change and p value
col_of_interest = "Sample_Group"
log2fc = fit00$coefficients[,col_of_interest]
##pval = p.adjust(fit$p.value[,2], method="bonferroni")
pval0 = p.adjust(fit00$p.value[,col_of_interest], "BH")
length(pval0[pval0<0.05]) # 229,730

cpg <- data.frame(logFC=log2fc, pval=pval0)
sig_hyper <- rownames(cpg[cpg$logFC>0 & cpg$pval<0.05,])
length(sig_hyper)
# save(sig_hyper, file='sig_hyper.RData')
sig_hypo <- rownames(cpg[cpg$logFC<0 & cpg$pval<0.05,])
# save(sig_hypo, file='sig_hypo.RData')
length(sig_hypo)

table_fit00 = topTable(fit00, num=Inf, coef=col_of_interest, adjust.method = "BH")
table_fit00$Type = ifelse(table_fit00$logFC>0, "Hyper", "Hypo")
sum(table_fit00$adj.P.Val<0.05) # 229,730

## Make a volcano plot (label DMP with different colors)
col_list = sapply(seq(1, dim(fit00$coefficients)[1]), function(i) {
  if (pval0[i]<0.05) {return("red")}
  else {return("black")} })
table(col_list)

pdf(file = "/home/liuwent/04-Full_Model/07-fit00.pdf")
par(cex.axis = 1.5, cex.lab = 1.5) 

volcanoplot(fit00, coef=2, col=col_list, highlight=5,
            names=rownames(fit00$coefficients))
# abline(h=-log10(0.05), lty=2, col="red")
abline(v=-1, lty=2, col="grey")
abline(v=1, lty=2, col="grey")
text(-1, 5, "x=-1", cex=1.2)
text(1, 5, "x=1", cex=1.2)
dev.off()