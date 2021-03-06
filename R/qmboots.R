qmboots <- function(dataset, nfactors, nsteps, load="auto", rotation="varimax", indet="qindtest", fsi=TRUE, ...) {
  startime <- Sys.time()
  nstat <- nrow(dataset)
  nqsorts <- ncol(dataset)
  ##number of iterations requested
  itnumber <- paste("Number of requested iterations: ",nsteps,sep="")
  print(itnumber, quote=FALSE)
  
  #-----------------------------------------------
  # A. create objects and slots for the results
  #-----------------------------------------------
  #bootstrap results
  qmbr <- vector("list", nfactors)
  names(qmbr) <- paste0("factor_", 1:nfactors)
  n <- 1
  while (n <= nfactors) {
    qmbr[[n]] <- vector("list", 3)
    qmbr[[n]][[1]] <- data.frame(matrix(FALSE, nrow=nqsorts, ncol=nsteps, dimnames=list(names(dataset), paste0("step_",1:nsteps))))
    qmbr[[n]][[2]] <- data.frame(matrix(as.numeric(NA), nrow=nstat, ncol=nsteps, dimnames=list(row.names(dataset), paste0("step_",1:nsteps))))
    qmbr[[n]][[3]] <- data.frame(matrix(as.numeric(NA), nrow=nqsorts, ncol=nsteps, dimnames=list(names(dataset), paste0("step_",1:nsteps))))
    names(qmbr[[n]]) <- c("flagged", "zsc", "loa")
    n <- n+1
  }
  #indeterminacy tests results
  if (indet == "procrustes") {
  } 
  if (indet == "qindtest" | indet == "both") {
    #create dataframe for results and reports from INDETERMINACY issue
    qmts <- list()
    qmts[[1]] <- data.frame(matrix(NA, nrow=nfactors, ncol=nsteps, dimnames=list(paste0("f",c(1:nfactors)), paste0("order_",1:nsteps))))
    qmts[[2]] <- data.frame(matrix(NA, nrow=nfactors, ncol=nsteps, dimnames=list(paste0("f",c(1:nfactors)), paste0("sign_",1:nsteps))))
    names(qmts) <- c("torder", "tsign")
    qmts_log <- list()
    qmts_log[[1]] <- data.frame(matrix(NA, nrow=1, ncol=nsteps, dimnames=list("log", paste0("log_ord_",1:nsteps))))
    qmts_log[[2]] <- data.frame(matrix(NA, nrow=1, ncol=nsteps, dimnames=list("log", paste0("log_sig_",1:nsteps))))
    names(qmts_log) <- c("torder", "tsign")
  }
  
  #-----------------------------------------------
  # B. full sample Q method loadings
  #-----------------------------------------------
  #use manually introduced matrix of factor loadings as target, if any
  if (is.matrix(load) | is.data.frame(load)) {
    if ((nrow(load) == nqsorts) & (ncol(load) == nfactors)) {
      flagged <- qflag(loa=load, nstat=nstat)
      qm <- qzscores(dataset, nfactors, flagged=flagged, loa=load)
      target <- load
      colnames(target) <- paste0("target_f", 1:nfactors)
    } else stop("Q method input: The factor loading matrix provided in 'load' should have the correct number of Q-sort as rows and the correct number of rotated factors as columns.")
  } else if (is.character(load) & length(load) == 1) {
    if (load == "auto") {
      qm <- qmethod(dataset, nfactors, rotation=rotation, ...)
      target <- as.matrix(qm$loa)
      colnames(target) <- paste0("target_f", 1:nfactors)
    } else stop("Q method input: 'load' has to be either 'auto' or a matrix.")
  }
  #create vector to build resamples
  #list of number of Q sorts, repeated as many times as bootstrap replications, to ensure that each Q-sort appears the same amount of times
  qsvector <- rep(1:nqsorts, times=nsteps)
  #generate a random order for the previous list
  qsrand <- sample(1:(nqsorts*nsteps), size=(nqsorts*nsteps), replace=FALSE)
  #order qsvector randomly
  qsvector <- qsvector[qsrand]
  
  #-----------------------------------------------
  # C. actual bootstrap
  #-----------------------------------------------
  it_count <- 1
  while (it_count <= nsteps) {
    qp <- 1 + (nqsorts*(it_count-1))
    #create bootstrap resample
    subdata <- dataset[ , qsvector[c(qp:(qp+(nqsorts-1)))]]
    #reshape target matrix of original factor loadings
    subtarget <-   target[qsvector[c(qp:(qp+(nqsorts-1)))],]
    #full bootstrap step
    step_res <- qbstep(subdata=subdata, subtarget=subtarget, 
                       indet, nfactors, nqsorts, nstat, 
                       qmts=qmts, qmts_log=qmts_log, 
                       rotation="unknown", flagged=flagged, ...)
    #Export necessary results
    n <- 1
    while (n <= nfactors) {
      #flagged q sorts
      qmbr[[n]][["flagged"]][paste0("step_",it_count)] <- step_res[[1]][[n]]
      #z-scores
      qmbr[[n]][["zsc"]][paste0("step_",it_count)] <- step_res[[2]][[n]]
      #factor loadings -- important to assign to the correct columns!
      for (r in 1:nqsorts) {
        if (sum(rownames(qmbr[[n]][[3]])[r] == names(subdata)) != 0) { #if the Q sort is in the resample...
          qmbr[[n]][["loa"]][r,it_count] <- step_res[[3]][[n]][which(rownames(qmbr[[n]][[3]])[r] == names(subdata))]
        }
        colnames(qmbr[[n]][[3]])[it_count] <- paste0("step_",it_count)
      }
      n <- n+1 
    }
    #Export results of indeterminacy correction, if any
    if (indet == "both" | indet == "qindtest") {
      #test results (logical)
      qmts[[1]][paste("order_",it_count, sep="")] <- step_res[[4]]
      qmts[[2]][paste("sign_",it_count, sep="")]  <- step_res[[5]]
      #reports of solution implementation
      qmts_log[[1]][paste("log_ord_",it_count, sep="")] <- step_res[[6]]
      qmts_log[[2]][paste("log_sig_",it_count, sep="")] <- step_res[[7]]
    }
    #iteration counting
    it_msg <- paste("Finished iteration number ",it_count, sep="")
    print(it_msg, quote=FALSE)
    it_count <- it_count + 1
  }
  #---actual bootstrap ends here
  #-----------------------------------------------
  
  #export indeterminacy results into one object
  qindet <- list()
  if (indet == "none") {
    qindet <- "Caution: no correction of PCA bootstrap indeterminacy issue was performed. This may introduced inflated variability in the results"
  }
  if (indet == "procrustes") {
    qindet <- "Procrustes rotation from MCMCpack was used to solve the PCA indeterminacy issue ('alignment problem')"
  }
  if (indet == "qindtest" | indet == "both") {
    qindet[[1]] <- qmts
    qindet[[2]] <- qmts_log
  }
  
  #-----------------------------------------------
  #E-bis. Test which steps could not be swap corrected
  #-----------------------------------------------
  if (indet == "qindtest" | indet == "both") {
    errmsg <- "ERROR in ORDER swap: at least one factor in the resample is best match for two or more factors in the target"
    badsteps <- which(qindet[[2]][[1]] == errmsg)
    print(paste("Number of steps with order swap error:", 
                length(badsteps)))

  } else badsteps <- 0
  
  #-----------------------------------------------
  # D. summary stats for z-scores of bootstrap
  #-----------------------------------------------
  qmbs <- list() #q method bootstrap summary
  n <- 1
  if (indet == "qindtest" | indet == "both") {
    while (n <= nfactors) {
      qmbs[[n+1]] <- merge(describe(t(qmbr[[n]][[2]][,-badsteps])), 
                           t(apply(qmbr[[n]][[2]][,-badsteps], 1, quantile, 
                                   probs=c(0.025, 0.25, 0.75, 0.975), 
                                   na.rm=TRUE)), 
                           by='row.names', sort=FALSE)
      rownames(qmbs[[n+1]]) <- qmbs[[n+1]][,1]
      qmbs[[n+1]][,1] <- NULL
      n <- n+1
    }
  } else {
    while (n <= nfactors) {
      qmbs[[n+1]] <- merge(describe(t(qmbr[[n]][[2]])), 
                           t(apply(qmbr[[n]][[2]], 1, quantile, 
                                   probs=c(0.025, 0.25, 0.75, 0.975), 
                                   na.rm=TRUE)), 
                           by='row.names', sort=FALSE)
      rownames(qmbs[[n+1]]) <- qmbs[[n+1]][,1]
      qmbs[[n+1]][,1] <- NULL
      n <- n+1
    }
  }
  names(qmbs) <- paste("factor",0:nfactors, sep="")
  #factor scores (fragment adapted from qzscores.R)
  qscores <- sort(dataset[,1], decreasing=FALSE)
  #build frame for fscores
  zsc_mea <- data.frame(zsc_mea=c(1:nstat), row.names=row.names(dataset))
  zsc_bn <- data.frame(zsc_bn=c(1:nstat), row.names=row.names(dataset))
  f <- 1
  while (f <= nfactors) {
    zsc_mea[,f] <- qmbs[[f+1]]$mean
    f <- f+1
  }
  colnames(zsc_mea) <- paste("zsc_mea_f",c(1:nfactors),sep="")
  f <- 1
  while (f <= nfactors) {
    s <- 1
    while (s <= nstat) {
      #find which statement has the current qscore rank
      statement <- order(zsc_mea[,f])[[s]]
      zsc_bn[statement,f] <- qscores[[s]]
      s <- s+1
    }
    f <- f+1
  }
  colnames(zsc_bn) <- paste("fsc_f",c(1:nfactors),sep="")
  qmbs[[1]] <- zsc_bn
  names(qmbs)[1] <- c("Bootstraped factor scores")
  
  #-----------------------------------------------
  # E. summary stats for loadings of bootstrap
  #-----------------------------------------------
  qmbl <- list()
  n <- 1
  if (indet == "qindtest" | indet == "both") {
    while (n <= nfactors) {
      qmbl[[n]] <- merge(describe(t(qmbr[[n]][[3]][,-badsteps])), t(apply(qmbr[[n]][[3]][,-badsteps], 1, quantile, probs=c(0.025, 0.25, 0.75, 0.975), na.rm=TRUE)), by='row.names', sort=FALSE)
      rownames(qmbl[[n]]) <- qmbl[[n]][,1]
      qmbl[[n]][,1] <- NULL
      qmbl[[n]] <- qmbl[[n]][order(row.names(qmbl[[n]])), ]
      qmbl[[n]]$flag_freq <- as.numeric(NA*nqsorts)
      for (j in 1:nqsorts) {
        qmbl[[n]][j,"flag_freq"] <- length(which(t(qmbr[[n]][[1]][,-badsteps])[,j] == TRUE)) / (length(which(t(qmbr[[n]][[1]][,-badsteps])[,j] == TRUE)) + length(which(t(qmbr[[n]][[1]][,-badsteps])[,j] == FALSE)))
      }
      n <- n+1
    }
  } else {
    while (n <= nfactors) {
      qmbl[[n]] <- merge(describe(t(qmbr[[n]][[3]])), t(apply(qmbr[[n]][[3]], 1, quantile, probs=c(0.025, 0.25, 0.75, 0.975), na.rm=TRUE)), by='row.names', sort=FALSE)
      rownames(qmbl[[n]]) <- qmbl[[n]][,1]
      qmbl[[n]][,1] <- NULL
      qmbl[[n]] <- qmbl[[n]][order(row.names(qmbl[[n]])), ]
      qmbl[[n]]$flag_freq <- as.numeric(NA*nqsorts)
      for (j in 1:nqsorts) {
        qmbl[[n]][j,"flag_freq"] <- length(which(t(qmbr[[n]][[1]])[,j] == TRUE)) / (length(which(t(qmbr[[n]][[1]])[,j] == TRUE)) + length(which(t(qmbr[[n]][[1]])[,j] == FALSE)))
      }
      n <- n+1
    }
  }
  names(qmbl) <- paste("factor",1:nfactors, sep="")
  #export and report
  qmboots <- list()
  qmboots[[1]] <- qmbs
  qmboots[[2]] <- qmbr
  qmboots[[3]] <- qindet
  qmboots[[4]] <- as.data.frame(matrix(qsvector, nrow=nqsorts, dimnames=list(NULL,paste("bsampl_", 1:nsteps, sep=""))))
  qmboots[[5]] <- qm
  qmboots[[6]] <- qscores
  qmboots[[7]] <- qmbl
  if (fsi == TRUE) {
    #calculate FACTOR STABILITY INDEX
    fsii <- qfsi(nfactors=nfactors, nstat=nstat, qscores=qscores, zsc_bn=zsc_bn, qm=qm)
    qmboots[[8]] <- fsii
    names(qmboots) <- c("zscore-stats", "Full bootstrap results", "Indeterminacy tests", "Resamples", "Original results", "Q board values", "Loading stats", "Stability index")
  } else {
    names(qmboots) <- c("zscore-stats", "Full bootstrap results", "Indeterminacy tests", "Resamples", "Original results", "Q board values", "Loading stats")
  }
  fintime <- Sys.time()
  duration <- paste(format(floor(difftime(fintime, startime, units="hours")[[1]]), width=2),":", format(floor(difftime(fintime, startime, units="mins")[[1]] %% 60), width=2),":", format(floor(difftime(fintime, startime, units="secs")[[1]] %% 60), width=2), sep="")
  cat("-----------------------------------------------\nBootstrap of ",nsteps," steps\nCall: qmboots(nfactors=",nfactors, ", nstat=", nstat, ", nqsorts=",nqsorts, ", nsteps=",nsteps, ", load=", load, ", rotation=", rotation, ", indet=",indet, ", fsi=",fsi,") \n-----------------------------------------------\nSTARTED : ",format(startime)," \nFINISHED: ", format(Sys.time()), "\nDURATION:            ", duration, " hrs:min:sec","\n-----------------------------------------------\nAlignment correction method: ",indet,"\nNumber of steps that could not be reordered: ",length(badsteps), "\n", sep="")
  invisible(qmboots)
}
#TO-DO: set printing method to show the bootstrapped z-scores, factor scores and stability indices