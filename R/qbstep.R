qbstep <- function(subdata, subtarget, indet, nfactors, nqsorts, nstat, 
                   qmts=qmts, qmts_log=qmts_log, rotation="unknown", 
                   flagged=flagged, ...) {
  #solutions for indeterminacy issue in PCA bootstrap
  loa <- as.data.frame(PCA(subdata, graph=FALSE)$var$coord[,c(1:nfactors)]) #PCA() from 'FactoMineR' is used instead of principal() from 'psych', because the latter does not return any values for some of the loadings, and it only returns three decimals
  if (indet == "none") {
    #loa <- as.data.frame(PCA(subdata, graph=FALSE)$var$coord[,c(1:nfactors)])
    loa <- as.data.frame(unclass(varimax(as.matrix(loa))[[1]]))
  }
  if (indet == "procrustes") {
    #loa <- as.data.frame(PCA(subdata, graph=FALSE)$var$coord[,c(1:nfactors)])
    #caution: selecting rotation ="varimax" here implies that both varimax and Procrustes are used one on top of the other, and probably just one or the other should be used. For the qindtest though, the selected rotation is used
    procrustes <- qpcrustes(loa=loa, target=subtarget, nfactors=nfactors)
    loa <- procrustes
  }
  if (indet == "qindtest" | indet == "both") {
    loa <- as.data.frame(unclass(varimax(as.matrix(loa))[[1]]))
    qindeterminacy <- qindtest(loa=loa, target=subtarget, 
                               nfactors=nfactors)
    loa <- qindeterminacy[[1]]
    if (indet == "both") {
      loa <- qpcrustes(loa=loa, target=subtarget, nfactors=nfactors)
    }
  }
  #z-scores and factor scores with the indeterminacy corrected factor loadings
  flagged <- qflag(nstat=nstat, loa=loa)
  qstep <- qzscores(subdata, nfactors=nfactors,  
                    flagged=flagged, loa=loa, ...)
  #export necessary results
  step_res <- list()
  step_res[[1]] <- list()
  step_res[[2]] <- list()
  step_res[[3]] <- list()
  n <- 1
  while (n <= nfactors) {
    #flagged q sorts
    step_res[[1]][n] <- qstep[[4]][n] #to append in qmbr[[n]][[1]]
    #z-scores
    step_res[[2]][n] <- qstep[[5]][n] #to append in qmbr[[n]][[2]] previously [,n]?
    #factor loadings
    step_res[[3]][n] <- qstep[[3]][n] #to append in qmbr[[n]][[3]]
    n <- n + 1
  }
  if (indet == "qindtest" | indet == "both") {
    qindt_log <- qindeterminacy[[2]]
    qindt <- qindeterminacy[[3]]
    #test results (logical)
    step_res[4] <- qindt[1] #to append in qmts[1]
    step_res[5] <- qindt[2] #to append in qmts[2]
    #reports of solution implementation
    step_res[6] <- qindt_log[1] #to append in qmts_log[1]
    step_res[7] <- qindt_log[2] #to append in qmts_log[2]
    names(step_res) <- c("flagged", "z_scores", "loadings", "torder_res_log", "tsign_res_log", "torder_res_report", "tsign_res_report")
  } else {names(step_res) <- c("flagged", "z_scores", "loadings")}
  return(step_res)
}