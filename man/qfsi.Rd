\name{qfsi}
\alias{qfsi}
\title{Q Methodology: Factor Stability index}
\description{Calculates Factor Stability index and Normalised Factor Stability index to bootstrapped Q method results}
\usage{qfsi(nfactors, nstat, qscores, zsc_bn, qm)}

\arguments{
  \item{nfactors}{number of factors to extract using PCA.}
  \item{nstat}{number of statements in the study.}
  \item{qscores}{all possible factor score values in the Q board.}
  \item{zsc_bn}{bootstrapped factor scores.}
  \item{qm}{original Q method results from qmethod() function.}
}
\details{
Applies Factor Stability index to a bootstrapped Q method results. Returns a data frame with two variables and as many rows as factors extracted. The first variable is the raw Factor Stability index. The second variable is the Normalised Factor Stability index which ranges from 0 to 1.}

\references{Zabala, A., 2012 \emph{title to determine}, Journal to determine.}

\author{Aiora Zabala}

\seealso{
\code{\link{qmboots}}.
}
\examples{
data(lipset)
boots <- qmboots(lipset[[1]], nfactors=3, nsteps=10, 
           rotation="varimax", indet="procrustes",
           fsi=FALSE)
fsi <- qfsi(nfactors=3, nstat=33, qscores=boots[[6]], 
           zsc_bn=boots[[1]][[1]], qm=boots[[5]])
fsi
}

\keyword{Q methodology}
