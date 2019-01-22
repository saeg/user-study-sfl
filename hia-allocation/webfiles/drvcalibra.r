#################
#
#  Script for semi-intentional sequential allocations 
# 

library(irr)
rm(list=ls())
source('liballoc01.r')
source('rdirichlet.r')

#
# Draw random samples
#   q: vector variables cardinality;
#      q[j] = number of categories of j-th variable 
#      Ex: q = c(3,4,4)
#   szsmp: sample size (number of individuals)
#   changepr: probability of changing individual averages in each category
#
DrawSample = function(q, szsmp, changepr=0.2) {
  matX = matrix(0, nrow=szsmp, ncol=sum(q))
  probs = list()
  for (j in 1:length(q)) {
    probs[[j]] = as.vector(rdirichlet2(1,rep(1,q[j])))
  }
  for (i in 1:szsmp) {
    if (runif(1)<changepr) {
      for (j in 1:length(q)) {
        probs[[j]] = as.vector(rdirichlet2(1,rep(1,q[j])))
      }
    }
    x = c()
    for (j in 1:length(q)) {
      x = c(x, rmultinom(1,1,probs[[j]]))
    }
    matX[i,] = x
  }
  return(matX)
}



dirdata = 'io'

wfile = paste(dirdata, '/w.txt', sep='')
qfile = paste(dirdata, '/q.txt', sep='')
alphafile = paste(dirdata, '/alpha.txt', sep='')
freqfile = paste(dirdata, '/freq.txt', sep='')
xfile = paste(dirdata, '/x.txt', sep='')
outfile = paste(dirdata, '/out.txt', sep='')



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
# alpha = scan(alphafile, what=double())

qtgroups = 8
szsmp = 30
qtsamples = 300
qtalloc = 100

#############Parei aqui

#Freq = matrix(round(runif(sum(q)*3)*10),ncol=sum(q))
priori=NULL
privect = SetPrioris(priori, q)

alphas = c(seq(0, 0.5, by=0.05), 1)

Dists = matrix(0,nrow=qtsamples, ncol=length(alphas))
Kappas = matrix(0,nrow=qtsamples, ncol=length(alphas))
MAlocs = matrix(0,nrow=qtsamples, ncol=length(alphas))

for (ida in 1:length(alphas)) {
  alpha = alphas[ida]   
  for (ids in 1:qtsamples) {
    print(c(alpha, ids))
    print(date())
    matX = DrawSample(q, szsmp, changepr=0.2)
    
    matAlloc = matrix(0, nrow=szsmp, ncol=qtalloc)
    dists = rep(0, qtalloc)
    gralloc = rep(0, qtalloc)
    for (idalloc in 1:qtalloc) {
      Freq = matrix(0,nrow=qtgroups, ncol=sum(q))
      for (i in 1:szsmp) {
        x = matX[i,]
        
        idgrupo = SI_Alloc(x, Freq, w, q, alpha)
        matAlloc[i, idalloc] = idgrupo
        Freq[idgrupo,] = Freq[idgrupo,] + x
        #print(c(alpha, ids, i, idgrupo))
        #browser()
      }
      dists[idalloc] = CompDistance(Freq, w, q, privect)
      gralloc[idalloc] = length(unique(matAlloc[,idalloc]))
    }
    Dists[ids, ida] = mean(dists)
    Kappas[ids,ida] = kappam.fleiss(matAlloc, exact = TRUE)$value
    MAlocs[ids,ida] = mean(gralloc)
  }
}

colnames(Dists)=colnames(Kappas)=colnames(MAlocs) = alphas

write.table(Dists, 'Dists.txt', col.names=TRUE, row.names=FALSE)
write.table(Kappas, 'Kappas.txt', col.names=TRUE, row.names=FALSE)
write.table(MAlocs, 'MAlocs.txt', col.names=TRUE, row.names=FALSE)




