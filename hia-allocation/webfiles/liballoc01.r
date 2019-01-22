################
#
#  aloc130718.r
#

library(robCompositions)
#library(hitandrun)

# Funcao para calcular as frequencias no conjunto de dados
# nos dois grupos
# O vetor resultante contem 2 linhas e t colunas onde t eh o numero
# total de categorias
# Duas ultimas colunas de cada linha contem:
# [qt indiv dentro do grupo, qt indiv fora do grupo]
freq = function(dados){  
  if(is.null(dados)){
    return(0)
  }
  f = NULL
  for (i in 1:ncol(dados)){
    ### CUIDADO - essa tabulacao retorna sempre o mesmo numero de linhas?
    Tabela = table(dados$Grupo,dados[,i])
    if (colnames(dados)[i] == 'Grupo') {
      Tabela[2,1] = Tabela[2,2]
      Tabela[1,2] = Tabela[2,2]
      Tabela[2,2] = Tabela[1,1]
    }
    f <- cbind(f,Tabela)
  }
  return(f)
}


# Funcao para converter variaveis categoricas em binarias em um dataset 
# (atraves da criacao de vetores caracteristicos)
#
Cat2Bin = function(dados, colunas=1:ncol(dados)){
  f = NULL
  for (i in colunas){
    #f <- cbind(f,table(dados[,1],dados[,i]))
    f <- cbind(f,table(1:nrow(dados),dados[,i]))
  }
  return(f)
}


#
# Dado um vetor de frequencias nas categorias, calcula as respectivas proporcoes
#
freq2prop = function(X, ncat=length(X), priori=0) {
  props = rep(0,length(X))
  Xaux = X+priori
  j=0
  for (i in 1:length(ncat)) {
    props[j+(1:ncat[i])] = Xaux[j+(1:ncat[i])]/sum(Xaux[j+(1:ncat[i])])
    j = j + ncat[i]
  }
  return(props)
}


#
# Dada uma matriz de frequencias nas categorias de diversas variáveis, retorna 
# uma matriz contendo as respectivas proporções 
#
Martrfreq2prop = function(X, ncat=length(X), priori=0) {
  props = rep(0,length(X))
  Xaux = X+priori
  j=0
  for (i in 1:length(ncat)) {
    props[j+(1:ncat[i])] = Xaux[j+(1:ncat[i])]/sum(Xaux[j+(1:ncat[i])])
    j = j + ncat[i]
  }
  return(props)
}




# Distancia Media (de Aitchison) entre as k componentes de X e Y, ponderada por (p1,...,pk)
# tdist: tipo de distancia: 'AIT'=Aitchison, 'MAX'=max 
aDistP = function(X, Y, tdist='AIT', ncat=length(X), priori=NULL, r1=0, r2=0, W=1, Wsam=1, epsmoeda=0){
  # Assume-se que as 3 ultimas componentes de X e Y sejam: grupo(2c), moeda1(2c), moeda2(2c)
  
  qtatr = length(ncat)-1  # 
  sncat <- cumsum(ncat)

  # priori
  if (length(priori)==0) {
    priori = Calcula_Priori(ncat)  
  } 
  
  if(length(W)==1) { 
    W <- rep(W,qtatr) 
  } 
  W = c(W, Wsam)
  
  X = freq2prop(X, ncat, priori)
  Y = freq2prop(Y, ncat, priori)
  X = freq2prop(X+r1, ncat, priori=0)
  Y = freq2prop(Y+r2, ncat, priori=0)
  
  j <- 1
  d <- 0

  for(i in 1:(length(sncat))){
    xi = X[j:sncat[i]]
    yi = Y[j:sncat[i]]
    d = ifelse(tdist %in% c('AIT', 'RND'), d + W[i]*aDist(xi, yi), 
                            max(c(d, W[i]*abs(xi-yi))))
    j <- sncat[i]+1
  }
  
  limites = c(1e-10, 1-(1e-10))
  #set.seed(1)   # apenas para depuracao
  a1 = runif(1, limites[1], limites[2])
  a2 = runif(1, limites[1], limites[2])
  distmoeda = aDist(c(a1, 1-a1), c(a2, 1-a2))
  
  return(d*(1-epsmoeda)/sum(W) + epsmoeda*distmoeda)
}

runifsimplex = function(N, d) {
  M = matrix(0, nrow=N, ncol=d)
  for (i in 1:N) {
    w = c(0, sort(runif(d-1)), 1)
    neww = w[2:(d+1)] - w[1:d]
    M[i,] = neww
  }
  return(M)
}


# Gera um vetor aleatorio onde cada subvetor tem norma epsilon
Rand = function(ncat,epsilon){
  sncat = cumsum(ncat)
  u <- rep(0, sum(ncat))
  j <- 1
  for(i in 1:(length(ncat))){
    u[j:sncat[i]] = as.vector(runifsimplex(1, ncat[i]))
    j <- sncat[i]+1
  }
  return(epsilon*u)
}


#
#  Funcao para calculo do numeto de categorias por variavel 
#

Calcula_NCateg = function(dados) {
  ncat <- NULL
  for (j in 1:ncol(dados)){
    dados[,j] <- factor(dados[,j], levels=levels(as.factor(as.vector(dados[,j]))))
    # No de categorias de cada variavel
    ncat <- c(ncat,nlevels(dados[,j]))
  }
  return(ncat)
}


# Calcula Priori pelo criterio do artigo: em cada variavel, priori = 1/q_j 
# onde q_j eh o numero de categorias da variavel j

Calcula_Priori = function(ncat) {
  priori = rep(0, sum(ncat))
  j = 0
  for (i in 1:length(ncat)) {
    priori[j+1:ncat[i]] = 1/ncat[i]
    j = j+ncat[i]
  }
  return(priori)  
}



# Funcao que faz a alocação de 'dados' em um dos dois grupos, com base nos 'alocados' anteriormente
#
# dados: data frame com dados dos pacientes alocados e dados 
#        (1a coluna contem id do paciente, ult coluna contem o grupo, demais contem as variaveis)
# W: vetor de pesos das variaveis, para calculo da distancia ponderada entre os vetores dos dois grupos
# priori: escalar ou vetor representando a distribuicao a priori de pontos nas classes
# epsilon: escalar que controla as perturbacoes aleatorias (vetores de perturbacoes sao
#          gerados de tal forma que a norma euclidiana em cada variavel eh igual a epsilon)

# tdist: tipo de distancia: 'AIT'=Aitchison, 'MAX'=max, 
#                          'RND'=amostragem aleatoria simples (sorteia o tratamento para cada paciente) 
#
Aloca = function(dados, tdist='AIT', priori=NULL, epsilon=0, epsdec=0, W=1, Wsam=1, epsmoeda=0){

  # Acrescedada uma ultima coluna artificial com valores 1,2 para balanceamento das frequencias nos dois grupos
  dados$Grupo = c(1,rep(2,nrow(dados)-1))
  
  # Garante que todos os niveis de cada variavel (categorica) estarao presentes nos calculos
  ncat <- NULL
  for (j in 1:ncol(dados)){
    dados[,j] <- factor(dados[,j], levels=levels(as.factor(as.vector(dados[,j]))))
    # No de categorias de cada variavel
    ncat <- c(ncat,nlevels(dados[,j]))
  }
  totcat = sum(ncat)

  # priori
  if (length(priori)==0) {
    priori = Calcula_Priori(ncat)  
  } 
  
  if (tdist=='RND') {
    # Alocacao aleatoria
    dados$Grupo = 1+rbinom(nrow(dados),1,0.5) 
    fr = freq(dados)
  } else {
    
    # Aloca (aleatoriamente) o primeiro paciente caso ninguem ainda tenha sido alocado
    # Comentario Marcelo: se os grupos estao vazios, a escolha do grupo 1 ou grupo 2
    # para o 1o individuo eh irrelevante sob o aspecto da amostragem.
    # 25/10: recoloquei a 1a alocacao aleatoria de volta
    #
    ult=1
    # fixo: quebra de simetria; aleatoria: pode haver simetria  #1+rbinom(1,1,0.5) 
    dados$Grupo[ult] = 1+rbinom(1,1,0.5)
  
    # 
    MatrBin <- Cat2Bin(dados, colunas=1:ncol(dados))

    fr = freq(dados[1:ult,])
    
    
    # Aloca sequencialmente os dados pacientes
    while (ult < nrow(MatrBin)){
      # Vetores de frequencias absolutas dos pacientes ja alocados no dois grupos
  
      #fr = freq(dados[1:ult,])
      #print(fr)
      novop = ult+1

      #
      #  Precisamos plotar um grafico do decaimento de epsilon em funcao
      #  da constante
      #
      #epsdecai = (epsdec+1) / (epsdec+log2(novop)) * epsilon
      epsdecai = epsdec^novop * epsilon
      if (epsdecai>0) {
        r1 <- Rand(ncat,epsdecai)
        r2 <- Rand(ncat,epsdecai)
      } else {
        r1 = rep(0, totcat)
        r2 = rep(0, totcat)
      }

      #fr = freq(dados[1:ult,])
      fr1 = fr[1,]
      fr2 = fr[2,]
      
      #fr1 = freq2prop(fr1, ncat, priori)
      #fr2 = freq2prop(fr2, ncat, priori)
      
      #prop = rbind(freq2prop(fr[1,], ncat), freq2prop(fr[2,], ncat))
      #barplot(prop, names.arg=colnames(prop), beside=TRUE)
      #print(c(ult, aDistP(X=fr1, Y=fr2, r1, r2, ncat, W, tdist)))
      #Sys.sleep(0.05)
      
  
      # Tres ultimas colunas do vetor correspondem a:
      # - grupo ao qual o vetor pertence (2 cat)
      # - moeda 1 (2 cat)
      # - moeda 2 (2 cat)
      novopac = MatrBin[novop,]
      novopac[totcat-(1:0)] = c(1,0)
      vetbalanc = c(rep(0, totcat-1), 1)
      

      # calcula distancias nos dois cenarios 
      d1 <- aDistP(X=fr1+novopac, Y=fr2+vetbalanc, tdist, ncat, priori, r1, r2, W, Wsam, epsmoeda)
      d2 <- aDistP(X=fr1+vetbalanc, fr2+novopac, tdist, ncat, priori, r1, r2, W, Wsam, epsmoeda)
      
      if(d1<d2){
        dados$Grupo[novop] = 1
        fr[1,] = fr[1,] + novopac    # acumula no vetor de frequencias do grupo correspondente
        fr[2,] = fr[2,] + vetbalanc
        #fr[2, totcat-1] = fr[1,totcat]  # duas ultimas colunas sao do grupo
      } else{
        dados$Grupo[novop] = 2
        fr[2,] = fr[2,] + novopac    # acumula no vetor de frequencias do grupo correspondente
        fr[1,] = fr[1,] + vetbalanc
      }
      #print(fr)
      ult = novop
    }
    #cat("Os pacientes alocados no Grupo 1 foram:",sort(g1),"\n")
    #cat("Os pacientes alocados no Grupo 2 foram:",sort(g2),"\n")
    #print(freq(alocados))
  }    
  
  prop = rbind(freq2prop(fr[1,], ncat, priori), freq2prop(fr[2,], ncat, priori))
  distance = aDistP(X=fr[1,], Y=fr[2,], tdist, ncat=ncat, priori=priori, W=W, epsmoeda=0)
  #aDistP(X, Y, tdist='AIT', ncat=length(X), priori=0, r1=0, r2=0, W=1, Wsam=1, Pmoeda=0){
    
  colnames(prop) = colnames(fr)

  #print(fr)
  #print(prop)
  return(list(dados=dados, fr=fr, prop=prop, ncat=ncat, distance=distance))
}


#
# set the vector of prioris 
# 
SetPrioris = function(priori, q) {
  qtcol = sum(q)
  if (length(priori)==0) {
    privect = rep(0,qtcol)
    colatu = 0
    for (idv in 1:length(q)) {
      privect[colatu+(1:q[idv])] = 1/q[idv]
      colatu = colatu+q[idv]
    }
  } else {
    privect = rep(priori, qtcol)
  }
  return(privect)
}




#
# Given a matrix of individuals frequencies per group and categories, 
# compute the weighted sum of compositional distances in all variables    
#
# Depois explico melhor os parametros
# 
CompDistance = function(Freq, w, q, privect=NULL) {
  
  # Sum prioris to frequency matrix
  if (length(privect)==0) {
    Freqpos = Freq
  } else {
    Freqpos = t(t(Freq)+privect)
  }

  wdistance = 0 
  colatu = 0
  for (idv in 1:length(w)) {
    Freqsel = Freqpos[,colatu+(1:q[idv])]
    
    # Generalization of Aitchison distance for multiple compositional vectors
    # Glahn et al, 2007. Lecture Notes on Compositional Data Analysis
    totvar = sqrt(sum(variation(Freqsel, robust=FALSE))/ncol(Freqsel))
    
    wdistance = wdistance + w[idv]*totvar
    colatu = colatu + q[idv]
    #print(c(idg, idv, totvar, wdistance))
  }
  wdistance = wdistance / sum(w)

  return(wdistance)
}



#
# Semi-intentional allocation of a new individual in one of m groups 
# x: binary vector of new individual
# Freq: Frequency matrix of groups: Freq m x k
# w: weight vector of variables
# q: dimension vector of variables
# alpha: weight of random term in objective function
# priori: priori to avoid components with proportion 0
# 
SI_Alloc = function(x, Freq, w, q, alpha, priori=NULL, plotfile=NULL, varnames=NULL, catnames=list()) {
  qtcol = ncol(Freq)
  qtgroup = nrow(Freq)
  qtvar = length(q)
  szgroups = apply(Freq[,1:q[1]],1,sum)
  
  if ((length(w)!=length(q) & length(w)!=length(q)+1) | sum(q)!=ncol(Freq)) {
    stop('Error in IndivAlloc: incompatible q, w, Freq')
  }

  # Group sizes covariate
  Z = cbind(szgroups, sum(szgroups)-szgroups)
  if (length(w) == length(q)+1) wnew = w else wnew = c(w, max(w)*3)

  qnew = c(q, 2)
  qtvar = length(qnew)
  # Add group sizes to the frequency matrix
  FreqComp = cbind(Freq, Z) 

  # set the vector of prioris 
  privect = SetPrioris(priori, qnew)

  # Sum prioris to frequency matrix
  Freqpos = t(t(FreqComp)+privect)

  mindist = 1e+10
  idbest = 0
  xnew = c(x, c(1,0))
  permgroups = 1:qtgroup  #  sample(qtgroup, qtgroup, replace=FALSE)
  for (idg in permgroups) {
    Freqnew = Freqpos
    Freqnew[idg,] = Freqnew[idg,] + xnew

    # Compute the weighted sum of compositional distances in all variables    
    wdistance = CompDistance(Freqnew, wnew, qnew, privect=NULL)

    # Random noise (to be incorporated in objective function)
    u = runif(qtgroup)
    Freqrand = cbind(u,1-u)
    #rdistance = sqrt(sum(variation(Freqrand, robust=FALSE))/ncol(Freqrand))
    rdistance = CompDistance(Freqrand, w=1, q=2, privect=NULL)
 
    hybdistance = (1-alpha) * wdistance + alpha*rdistance
    
    #print(c(idg, wdistance, rdistance, hybdistance))
    #browser()
    
    if (hybdistance<mindist) {
      mindist = hybdistance
      idbest = idg
    }
  }
  #print(c(idbest, mindist))

  return(idbest)
}


#
# Semi-intentional allocation of a group of individuals in one of m groups 
# X: binary matrix of individuals
# qtalloc: number of different allocations for the same data X
# w: weight vector of variables
# q: dimension vector of variables
# alpha: weight of random term in objective function
# priori: priori to avoid components with proportion 0
#
# Value:
#   MAloc: allocation matrix
#   Freq: Frequency matrix of groups: Freq m x k
# 
SI_Alloc_Group = function(X, qtalloc, w, q, alpha, priori=NULL, plotfile=NULL, varnames=NULL, catnames=list()) {
  qtcol = ncol(Freq)
  qtgroup = nrow(Freq)
  qtvar = length(q)
  szgroups = apply(Freq[,1:q[1]],1,sum)
  
  if ((length(w)!=length(q) & length(w)!=length(q)+1) | sum(q)!=ncol(Freq)) {
    stop('Error in IndivAlloc: incompatible q, w, Freq')
  }
  
  # Group sizes covariate
  Z = cbind(szgroups, sum(szgroups)-szgroups)
  if (length(w) == length(q)+1) wnew = w else wnew = c(w, mean(w))
  
  qnew = c(q, 2)
  qtvar = length(qnew)
  # Add group sizes to the frequency matrix
  FreqComp = cbind(Freq, Z) 
  
  # set the vector of prioris 
  privect = SetPrioris(priori, qnew)
  
  # Sum prioris to frequency matrix
  Freqpos = t(t(FreqComp)+privect)
  
  mindist = 1e+10
  idbest = 0
  xnew = c(x, c(1,0))
  for (idg in 1:qtgroup) {
    Freqnew = Freqpos
    Freqnew[idg,] = Freqnew[idg,] + xnew
    
    # Compute the weighted sum of compositional distances in all variables    
    wdistance = CompDistance(Freqnew, wnew, qnew, privect=NULL)
    
    # Random noise (to be incorporated in objective function)
    u = runif(qtgroup)
    Freqrand = cbind(u,1-u)
    #rdistance = sqrt(sum(variation(Freqrand, robust=FALSE))/ncol(Freqrand))
    rdistance = CompDistance(Freqrand, w=1, q=2, privect=NULL)
    
    hybdistance = (1-alpha) * wdistance + alpha*rdistance
    
    #print(c(idg, wdistance, rdistance, hybdistance))
    
    if (hybdistance<mindist) {
      mindist = hybdistance
      idbest = idg
    }
  }
  #print(c(idbest, mindist))
  
  return(idbest)
}



