\name{qpcrustes}
\alias{qpcrustes}
\title{Q Methodology: Procrustes rotation of loadings}
\description{This is a wrap of \code{procrustes} rotation from \pkg{MCMCpack} for bootstrapping Q methodology in the function \code{\link{qmboots}}.}
\usage{qpcrustes(loa, target, nfactors)}

\arguments{
  \item{loa}{factor loadings from subsample analysis}
  \item{target}{factor loadings from full sample analysis}
  \item{nfactors}{fumber of factors}
}

\details{Returns the factor loadings for the subsample after applying Procrustes rotation to correct the indeterminacy issue. Uses \code{procrustes} from \pkg{MCMCpack}. Used within the function \code{\link{qmboots}}, not intended for independent use.
}

\references{text here}

\author{Aiora Zabala}

\seealso{
Function \link{procrustes} from \pkg{MCMCpack} package.
}
\examples{
data(lipset)
qm <- qmethod(lipset[[1]], nfactors=3, rotation="varimax")
qselim <- sample(1:3, 2, replace=FALSE) ##q sorts to eliminate
subdata <- lipset[[1]][ , -qselim]
library(psych)
loa <- as.data.frame(unclass(principal(subdata, 
           nfactors=3, rotate="varimax")$loadings))
target <- as.matrix(as.data.frame(qm[3]))
colnames(target) <- paste("target_f", 1:3, sep="")
subtarget <- target[c(-qselim),]
qindt <- qpcrustes(loa, subtarget, 3)
qindt
}

\keyword{multivariate}
\keyword{Q methodology}
\keyword{Procrustes rotation}
