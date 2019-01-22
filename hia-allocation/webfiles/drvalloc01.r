#################
#
#  Script for semi-intentional sequential allocations 
# 

# Chamada no Rscript:
# Rscript --vanilla drvalloc01.r 123
# onde 123 representa o id do novo individuo

rm(list=ls())

#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)
id = ifelse(length(args)==0, 0, args[1])

#browser()
dirdata = 'io'
source('liballoc01.r')

wfile = paste(dirdata, '/w.txt', sep='')
qfile = paste(dirdata, '/q.txt', sep='')
alphafile = paste(dirdata, '/alpha.txt', sep='')
freqfile = paste(dirdata, '/freq_',id,'.txt', sep='')
xfile = paste(dirdata, '/x_',id,'.txt', sep='')
outfile = paste(dirdata, '/out_',id,'.txt', sep='')


###############
# 
#  Parameters for the allocation program
#  (Must be defined once, previously to the experiment beginning)
#

#
# Some notation for sake of clarity:
#   k = number of variables
#   m = number of groups
#

# w: vector variables weights;
# w[j] = weight of j-th variable 
# w may contain an additional element, representing the weight of the additional 
# variable which controls the balance sizes of groups; If not specified, w[k+1] = mean(w)
#   Ex: w = c(2,1,1)
w = scan(wfile, what=double(), sep=';')

# q: vector variables cardinality;
# q[j] = number of categories of j-th variable 
#   Ex: q = c(3,4,4)
q = scan(qfile, what=integer(), sep=';')

# alpha: weight of random component in allocation in the objective function 
#      d_{\epsilon}(j) = (1-alpha) \Delta(X) + \aplha \Delta(R)
#    where \Delta(X) is the total variance of data matrix X and \Delta(R) is the total 
#    variance of random matrix R (explained in the allocation program source code and 
#    futurely in the paper)
#    Setting alpha = 0 corresponds to the deterministic allocation (minimization of the 
#             total variance in data matrix)
#    Setting alpha = 0 corresponds to the random allocation (minimization of the 
#             total variance in random matrix, disregarding any information in data)
# Recommendation: 0.05 < alpha < 0.5
#   Ex: alpha = 0.1
#
# Alpha value should be callibrated BEFORE the beginning of experiments
#
alpha = scan(alphafile, what=double())


# Frequencies matrix
Freq = read.table(freqfile, sep=';', header=FALSE, stringsAsFactors=FALSE)

# Binary vector corresponding to new individual
x = scan(xfile, sep=';', what=integer())

priori=NULL
privect = SetPrioris(priori, q)

# Allocation of new individual
idgrupo = SI_Alloc(x, Freq, w, q, alpha)
write(idgrupo, outfile)


