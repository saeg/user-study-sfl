#
#  Versao alterada da funcao rdirichlet do pacote MCMCpack
#  A funcao original nao garante que sum(x_i)=1, esta versao faz isso.
#
rdirichlet2 = function (n, alpha)
{
    l <- length(alpha)
    p = matrix(0, nrow=n, ncol=l)  # prepara matriz de saida
    out = 1:n                      # posicoes de p que precisam ser geradas

    while (length(out)>0) {  # enquanto houver vetores com soma <> 1

      # as proximas 3 linhas geram vetores com distribuicao dirichlet
      x <- matrix(rgamma(l*length(out), alpha), ncol = l, byrow = TRUE)
      sm <- apply(x,1,sum)
      prop = x / as.vector(sm, mode="numeric")

      # normalizacao de escala para aproximar a soma 1
      p[out,] = prop/apply(prop,1,sum)
      
      # verifica se hah vetores com soma <> 1
      out = which(1-apply(p,1,sum)!=0)
      #print(length(out))
    }

    return(p)
}
