#' Calculate exact AUCs based on the distribution of risk in a population
#'
#' Provided a distribution of risk in a population, this function calculates the
#' exact AUC of a model that produces the risk estimates.  For example, a logistic
#' regression model built with a normal linear predictor yields logit-normal distributed
#' predicted risks.  The AUC from the logistic regression model is the same as the AUC estimated
#' from the distribution of the predicted risks, independent of the outcome.  This method for AUC
#' calculation is useful for simulation studies where the predicted risks are a mixture of two
#' distributions.  The exact prevalence of the outcome can easily be calculated, along with the exact
#' AUC of the model.
#'
#' @author Daniel D Sjoberg \email{sjobergd@@mskcc.org}
#' @param density a function name that describes the continuous probability density function of the
#' risk from 0 to 1.
#' @param cut.points sequence of points in \[0, 1\] where the sensitivity and specificity are calculated.
#' More points lead to a more precise estimate of the AUC.  Default is seq(from = 0, to = 1,by = 0.001).
#' @param ... arguments for the function specified in density.  For example, dbeta(x, shape1=1, shape2=1)
#' has need for two additional arguments to specify the density function (shape1 and shape2).
#' @importFrom stats integrate
#' @return Returns a list sensitivity and specificity at each cut point, the expected value or
#' mean risk, and the AUC associated with the distribution.
#' @examples
#' auc_density(density = dbeta, shape1 = 1, shape2 = 1)
#' @export
#'
auc_density <- function(density, cut.points = seq(from = 0, to = 1, by = 0.001), ...) {
  # calculating distribution mean
  mu <- integrate(function(x) x * density(x, ...), 0, 1)$value

  sensitivity <- NULL
  specificity <- NULL
  for (c in cut.points) {
    # calculating Sens and Spec using Bayes Rule
    sens0 <- integrate(function(x) x * density(x, ...), c, 1)$value / mu
    spec0 <- (integrate(function(x) density(x, ...), 0, c)$value -
      integrate(function(x) x * density(x, ...), 0, c)$value) /
      (1 - mu)

    # appending calculated results
    sensitivity <- c(sensitivity, sens0)
    specificity <- c(specificity, spec0)
  }

  # calculating the AUC (using the trapezoidal rule)
  idx <- 2:length(cut.points)
  auc <- as.numeric(-(specificity[idx - 1] - specificity[idx]) %*% (sensitivity[idx] + sensitivity[idx - 1]) / 2)

  # retruning results
  results <- list(cut.points, sensitivity, specificity, mu, auc)
  names(results) <- c("cut.point", "sensitivity", "specificity", "mu", "auc")

  return(results)
}
