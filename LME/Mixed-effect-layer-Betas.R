library(gdata)
library(readxl)
library(ggplot2)
library(patchwork)
library(ggpubr)
library(nlme)
library(dplyr)
library(ggeffects)
library(stargazer)
library(writexl)
library(usdm)
library(car)
setwd('/media/kahmadi/Elements1/DavidsData/LMEs_all/denoised/')
Sub <- read_excel('Sub_all_newTrials.xlsx')
CA1 <- read_xlsx('CA1_all_newTrials.xlsx')
CA2 <- read_xlsx('CA2_all_newTrials.xlsx')
CA3 <- read_xlsx('CA3_all_newTrials.xlsx')
View(Sub)
View(CA1)
View(CA2)
View(CA3)


CA3 <- CA3[-c(1,1:10)] # remove SRLM-related bins in ca3

Sub[,37] <- scale(Sub$SI)
Sub[,38] <- scale(Sub$MDB)
Sub[,39] <- scale(Sub$drop_error)
Sub[,40] <- scale(Sub$trial_Num)
CA1[,37] <- scale(CA1$SI)
CA1[,38] <- scale(CA1$MDB)
CA1[,39] <- scale(CA1$drop_error)
CA1[,40] <- scale(CA1$trial_Num)
CA2[,37] <- scale(CA2$SI)
CA2[,38] <- scale(CA2$MDB)
CA2[,39] <- scale(CA2$drop_error)
CA2[,40] <- scale(CA2$trial_Num)
CA3[,27] <- scale(CA3$SI)
CA3[,28] <- scale(CA3$MDB)
CA3[,29] <- scale(CA3$drop_error)
CA3[,30] <- scale(CA3$trial_Num)
colnames(Sub)[37] <- "scale_SI"
colnames(Sub)[38] <- "scale_MDB"
colnames(Sub)[39] <- "scale_droperror"
colnames(Sub)[40] <- "scale_trial"
colnames(CA1)[37] <- "scale_SI"
colnames(CA1)[38] <- "scale_MDB"
colnames(CA1)[39] <- "scale_droperror"
colnames(CA1)[40] <- "scale_trial"
colnames(CA2)[37] <- "scale_SI"
colnames(CA2)[38] <- "scale_MDB"
colnames(CA2)[39] <- "scale_droperror"
colnames(CA2)[40] <- "scale_trial"
colnames(CA3)[27] <- "scale_SI"
colnames(CA3)[28] <- "scale_MDB"
colnames(CA3)[29] <- "scale_droperror"
colnames(CA3)[30] <- "scale_trial"


Cntr <- lmeControl(maxIter = 1000, msMaxIter = 1000, opt = 'optim', msVerbose = TRUE)


#### check the colinearity among predictors by testing for variance inflation rate. First run this function then use vif.lme 

vif.lme <- function (fit) {
  ## adapted from rms::vif
  v <- vcov(fit)
  nam <- names(fixef(fit))
  ## exclude intercepts
  ns <- sum(1 * (nam == "Intercept" | nam == "(Intercept)"))
  if (ns > 0) {
    v <- v[-(1:ns), -(1:ns), drop = FALSE]
    nam <- nam[-(1:ns)] }
  d <- diag(v)^0.5
  v <- diag(solve(v/(d %o% d)))
  names(v) <- nam
  v }


#####


bin.names <- colnames(CA1)[1:30] # This is for bins in Sub, CA1 and CA2
no.bin <- length(bin.names)

# create a named list to hold the fitted models for CA1 and CA2
fitlist <- as.list(1:no.bin)
names(fitlist) <- bin.names

DE <- data.frame(matrix(nrow = no.bin, ncol = 5))
MDB <- data.frame(matrix(nrow = no.bin, ncol = 5))
SI <- data.frame(matrix(nrow = no.bin, ncol = 5))
trial <- data.frame(matrix(nrow = no.bin, ncol = 5))
colnames(DE)[1:5] <- c("beta","SD","DF","t_val","p_val")
colnames(MDB)[1:5] <- c("beta","SD","DF","t_val","p_val")
colnames(SI)[1:5] <- c("beta","SD","DF","t_val","p_val")
colnames(trial)[1:5] <- c("beta","SD","DF","t_val","p_val")

fitlist1 <- as.list(1:no.bin)
names(fitlist1) <- bin.names

DE1 <- data.frame(matrix(nrow = no.bin, ncol = 5))
MDB1 <- data.frame(matrix(nrow = no.bin, ncol = 5))
SI1 <- data.frame(matrix(nrow = no.bin, ncol = 5))
trial1 <- data.frame(matrix(nrow = no.bin, ncol = 5))
colnames(DE1)[1:5] <- c("beta","SD","DF","t_val","p_val")
colnames(MDB1)[1:5] <- c("beta","SD","DF","t_val","p_val")
colnames(SI1)[1:5] <- c("beta","SD","DF","t_val","p_val")
colnames(trial1)[1:5] <- c("beta","SD","DF","t_val","p_val")


fitlist2 <- as.list(1:no.bin)
names(fitlist2) <- bin.names

DE2 <- data.frame(matrix(nrow = no.bin, ncol = 5))
MDB2 <- data.frame(matrix(nrow = no.bin, ncol = 5))
SI2 <- data.frame(matrix(nrow = no.bin, ncol = 5))
trial2 <- data.frame(matrix(nrow = no.bin, ncol = 5))
colnames(DE2)[1:5] <- c("beta","SD","DF","t_val","p_val")
colnames(MDB2)[1:5] <- c("beta","SD","DF","t_val","p_val")
colnames(SI2)[1:5] <- c("beta","SD","DF","t_val","p_val")
colnames(trial2)[1:5] <- c("beta","SD","DF","t_val","p_val")

# loop over bin names
for(i in bin.names){ 
  # print status
  print(paste("Running entity:", i, "which is", which(bin.names==i), "out of", no.bin)) 
  # choice of 4 predictors is justified because AIC is lower compared to single predictors or other combinations 
  fml <- as.formula( paste( i, "~", paste(c("scale_droperror","scale_MDB","scale_SI","scale_trial"), collapse="+") ) )
  
  # assign fit to list by name
  fitlist[[i]] <- lme(fml, random=~1|ID, na.action = na.omit, control = Cntr, data=Sub)
  DE[i,1:5] <- summary(fitlist[[i]])$tTable[2,1:5]
  MDB[i,1:5] <- summary(fitlist[[i]])$tTable[3,1:5]
  SI[i,1:5] <- summary(fitlist[[i]])$tTable[4,1:5]
  trial[i,1:5] <- summary(fitlist[[i]])$tTable[5,1:5]
  
  fitlist1[[i]] <- lme(fml, random=~1|ID, na.action = na.omit, control = Cntr, data=CA1)
  DE1[i,1:5] <- summary(fitlist1[[i]])$tTable[2,1:5]
  MDB1[i,1:5] <- summary(fitlist1[[i]])$tTable[3,1:5]
  SI1[i,1:5] <- summary(fitlist1[[i]])$tTable[4,1:5]
  trial1[i,1:5] <- summary(fitlist1[[i]])$tTable[5,1:5]
  
  fitlist2[[i]] <- lme(fml, random=~1|ID, na.action = na.omit, control = Cntr, data=CA2)
  DE2[i,1:5] <- summary(fitlist2[[i]])$tTable[2,1:5]
  MDB2[i,1:5] <- summary(fitlist2[[i]])$tTable[3,1:5]
  SI2[i,1:5] <- summary(fitlist2[[i]])$tTable[4,1:5]
  trial2[i,1:5] <- summary(fitlist2[[i]])$tTable[5,1:5]
  
}

DE <- DE[-c(1:30),]
MDB <- MDB[-c(1:30),]
SI <- SI[-c(1:30),]
trial <- trial[-c(1:30),]

DE1 <- DE1[-c(1:30),]
MDB1 <- MDB1[-c(1:30),]
SI1 <- SI1[-c(1:30),]
trial1<- trial1[-c(1:30),]

DE2 <- DE2[-c(1:30),]
MDB2 <- MDB2[-c(1:30),]
SI2 <- SI2[-c(1:30),]
trial2 <- trial2[-c(1:30),]

writexl::write_xlsx(DE,"DE_betas_SE_pval_perBin_Sub.xlsx",col_names = TRUE)
writexl::write_xlsx(MDB,"MDB_betas_SE_pval_perBin_Sub.xlsx",col_names = TRUE)
writexl::write_xlsx(SI,"SI_betas_SE_pval_perBin_Sub.xlsx",col_names = TRUE)
writexl::write_xlsx(trial,"trial_betas_SE_pval_perBin_Sub.xlsx",col_names = TRUE)


writexl::write_xlsx(DE1,"DE_betas_SE_pval_perBin_CA1.xlsx",col_names = TRUE)
writexl::write_xlsx(MDB1,"MDB_betas_SE_pval_perBin_CA1.xlsx",col_names = TRUE)
writexl::write_xlsx(SI1,"SI_betas_SE_pval_perBin_CA1.xlsx",col_names = TRUE)
writexl::write_xlsx(trial1,"trial_betas_SE_pval_perBin_CA1.xlsx",col_names = TRUE)

writexl::write_xlsx(DE2,"DE_betas_SE_pval_perBin_CA2.xlsx",col_names = TRUE)
writexl::write_xlsx(MDB2,"MDB_betas_SE_pval_perBin_CA2.xlsx",col_names = TRUE)
writexl::write_xlsx(SI2,"SI_betas_SE_pval_perBin_CA2.xlsx",col_names = TRUE)
writexl::write_xlsx(trial2,"trial_betas_SE_pval_perBin_CA2.xlsx",col_names = TRUE)


######### Multiple comparison correction using FDR 
corr_p_Sub = data.frame(matrix(NA,nrow = 30, ncol = 4))
corr_p_CA1 = data.frame(matrix(NA,nrow = 30, ncol = 4))
corr_p_CA2 = data.frame(matrix(NA,nrow = 30, ncol = 4))


corr_p_Sub[,1] <- p.adjust(DE[,5], method = 'fdr') 
corr_p_CA1[,1] <- p.adjust(DE1[,5], method = 'fdr')
corr_p_CA2[,1] <- p.adjust(DE2[,5], method = 'fdr')
  
corr_p_Sub[,2] <- p.adjust(MDB[,5], method = 'fdr')
corr_p_CA1[,2] <- p.adjust(MDB1[,5], method = 'fdr')
corr_p_CA2[,2] <- p.adjust(MDB2[,5], method = 'fdr')
  
corr_p_Sub[,3] <- p.adjust(SI[,5], method = 'fdr')
corr_p_CA1[,3] <- p.adjust(SI1[,5], method = 'fdr')
corr_p_CA2[,3] <- p.adjust(SI2[,5], method = 'fdr')

corr_p_Sub[,4] <- p.adjust(trial[,5], method = 'fdr')  
corr_p_CA1[,4] <- p.adjust(trial1[,5], method = 'fdr')
corr_p_CA2[,4] <- p.adjust(trial2[,5], method = 'fdr')

colnames(corr_p_Sub) <- c('DE','MDB','SI','trial')
colnames(corr_p_CA1) <- c('DE','MDB','SI','trial')
colnames(corr_p_CA2) <- c('DE','MDB','SI','trial')

writexl::write_xlsx(corr_p_Sub,"pval_Sub_Corrected.xlsx",col_names = TRUE)
writexl::write_xlsx(corr_p_CA1,"pval_CA1_Corrected.xlsx",col_names = TRUE)
writexl::write_xlsx(corr_p_CA2,"pval_CA2_Corrected.xlsx",col_names = TRUE)



## Get the VIF values. Since predictors are identical across bins and subregions, you can take any bins, e.g. bin10 

Var_inflat_fact <- data.frame(matrix(nrow = 1, ncol = 4))
colnames(Var_inflat_fact)[1:4] <- c("scale_DE","scale_MDB","scale_SI","scale_trial")

for(j in 1:4){ 
  Var_inflat_fact[,j] <- vif.lme(fitlist$bin10)[j]
}
# Values > 4 indicates strong co-linearity 
writexl::write_xlsx(Var_inflat_fact,"VIF_among_predictors.xlsx",col_names = TRUE)



################ Do the same  CA3
keep(CA3,Cntr, sure = T)

bin.names_CA3 <- colnames(CA3)[1:20] # This is for bins in sub & ca3
no.bin_CA3 <- length(bin.names_CA3)

fitlist <- as.list(1:no.bin_CA3)
names(fitlist) <- bin.names_CA3

DE <- data.frame(matrix(nrow = no.bin_sub, ncol = 5))
MDB <- data.frame(matrix(nrow = no.bin_sub, ncol = 5))
SI <- data.frame(matrix(nrow = no.bin_sub, ncol = 5))
trial <- data.frame(matrix(nrow = no.bin_sub, ncol = 5))
colnames(DE)[1:5] <- c("beta","SD","DF","t_val","p_val")
colnames(MDB)[1:5] <- c("beta","SD","DF","t_val","p_val")
colnames(SI)[1:5] <- c("beta","SD","DF","t_val","p_val")
colnames(trial)[1:5] <- c("beta","SD","DF","t_val","p_val")



for(i in bin.names_CA3){ 
  print(paste("Running entity:", i, "which is", which(bin.names_CA3==i), "out of", no.bin_CA3)) 
  fml <- as.formula( paste( i, "~", paste(c("scale_droperror","scale_MDB","scale_SI","scale_trial"), collapse="+") ) )
  
  fitlist[[i]] <- lme(fml, random=~1|ID, na.action = na.omit, control = Cntr, data=CA3)
  DE[i,1:5] <- summary(fitlist[[i]])$tTable[2,1:5]
  MDB[i,1:5] <- summary(fitlist[[i]])$tTable[3,1:5]
  SI[i,1:5] <- summary(fitlist[[i]])$tTable[4,1:5]
  trial[i,1:5] <- summary(fitlist[[i]])$tTable[5,1:5]
  
}

DE <- DE[-c(1:20),]
MDB <- MDB[-c(1:20),]
SI <- SI[-c(1:20),]
trial<- trial[-c(1:20),]

writexl::write_xlsx(DE,"DE_betas_SE_pval_perBin_CA3.xlsx",col_names = TRUE)
writexl::write_xlsx(MDB,"MDB_betas_SE_pval_perBin_CA3.xlsx",col_names = TRUE)
writexl::write_xlsx(SI,"SI_betas_SE_pval_perBin_CA3.xlsx",col_names = TRUE)
writexl::write_xlsx(trial,"trial_betas_SE_pval_perBin_CA3.xlsx",col_names = TRUE)


######### Multiple comparison correction using FDR  
corr_p_CA3 = data.frame(matrix(NA,nrow = 20, ncol = 4))

corr_p_CA3[,1] <- p.adjust(DE2[,5], method = 'fdr')
  
corr_p_CA3[,2] <- p.adjust(MDB2[,5], method = 'fdr')
  
corr_p_CA3[,3] <- p.adjust(SI2[,5], method = 'fdr')
  
corr_p_CA3[,4] <- p.adjust(trial2[,5], method = 'fdr')

colnames(corr_p_CA3) <- c('DE','MDB','SI','trial')
writexl::write_xlsx(corr_p_CA3,"pval_CA3_Corrected.xlsx",col_names = TRUE)