#' Permute costmatrices
#'
#' @description
#'
#' Given vectors of states and costs, permutes all possible costmatrices.
#'
#' @param states A vector of character states, e.g., "0", "1", "2".
#' @param costs A vector of numeric costs, e.g., 1, 2, Inf.
#'
#' @details
#'
#' Costmatrices define the cost of each state-to-state transition, but they are restricted in what these costs can be (see \link{check_costMatrix}). Nevertheless, strictly speaking there are infinite possible costmatrices - even where costs are restricted to integer values (as TNT does; Goloboff et al. 2008; Goloboff and Catalano 2016), i.e., "stepmatrices" (Swofford and Maddison 1992). Thus this function operates on a finite system by requiring the user to specify a restricted set of states and individual cost values, with the function permuting every possible combination of finite costs. Note that not \link{every} permutation will be returned as not all of these will be valid costmatrices (see \link{check_costMatrix} and \link{fix_costMatrix}). Others will not be returned because their cost \emph{ratio} can be considered redundant. For example, for a binary character (states "0", and "1") the following two costmatrices would be mutually redundant as the ratio of their costs is identical:
#'
#' \preformatted{  A B
#' A 0 1
#' B 2 0
#'
#'   A B
#' A 0 2
#' B 4 0}
#'
#' (If the user does want to consider these kinds of alternatives then a better solution is to simply weight the first matrix by two, or any other value, in any downstream analys(es).)
#'
#' For the function to work costs must be unique positive values. This includes infinity (\code{Inf} in R). Infinite costs can be used to denote a particular transition is impossible and allows defining (e.g.) irreversible characters, or those that force a particular root value.
#'
#' @return A list of unique costmatrices containing every possible combination of costs.
#'
#' @author Graeme T. Lloyd \email{graemetlloyd@@gmail.com}
#'
#' @references
#'
#' Goloboff, P. A. and Catalano, S. A., 2016. TNT version 1.5, including a full implementation of phylogenetic morphometrics/ \emph{Cladistics}, \bold{32}. 221-238
#'
#' Goloboff, P., Farris, J. and Nixon, K., 2008. TNT, a free program for phylogenetic analysis. \emph{Cladistics}, \bold{24}, 774-786.
#'
#' Swofford, D. L. and Maddison, W. P., 1992. Parsimony, character-state reconstructions, and evolutionary inferences. \emph{In} R. L. Mayden (ed.) Systematics, Historical Ecology, and North American Freshwater Fishes. Stanford University Press, Stanford, p187-223.
#'
#' @examples
#'
#' # Permute all the ways of assigning the costs 1, 2, 3 and infinity for
#' # a binary character:
#' permute_costmatrices(states = c("0", "1"), costs = c(1:3, Inf))
#'
#' # Permute all the ways to assign the costs 1 and 2 for a three state
#' # character:
#' permute_costmatrices(states = c("0", "1", "2"), costs = c(1, 2))
#'
#' @export permute_costmatrices
permute_costmatrices <- function(states = c("0", "1"), costs = c(1:3)) {
  
  # PERMUTE STATE GRAPHS THEN EDGE WEIGHTS AS AN ALTERNATE APPROACH?
  # WOULD REQUIRE A FUNCTION TO CONVERT A GRAPH TO A COSTMATRIX
  # AND MAYBE ADDING A stateGraph CLASS.
  
  ### ADD INFINITY VIOLATION CHECKS TO CHECK_COSTMATRIX!!!!!
  # Need to check infinity rules!!!!!!!!
  # NO - NEED TO FIX FIX_COSTMATRIX INSTEAD!
  ### NEW BOXES TO ADD TO MANUSCRIPT: 1. CLADDIS FUNCTIONS, 2. NOTATIONS FOR N_tips etc., 3. COSTMATRIX RULES.
  
  # Check states has positive length and stop and warn user if not:
  if (length(x = states) < 1) stop("states must have at least one value.")
  
  # Check states are in the form of characters and stop and warn user if not:
  if (!is.character(states)) stop("states must be a character vector. If they are 0, 1 etc. then place in quotes or use as.character().")
  
  # Check there are no duplicate states and stop and warn user if not:
  if (any(duplicated(x = states))) stop("states cannot include duplicate values.")
  
  # Check costs has positive length and stop and warn user if not:
  if (length(x = costs) < 1) stop("costs must have at least one value.")
  
  # Check costs are in the form of numbers and stop and warn user if not:
  if (!is.numeric(x = costs)) stop("costs must be a numeric vector.")
  
  # Check costs are all positive values and stop and war user if not:
  if (any(costs <= 0)) stop("costs must all be positive values.")
  
  # Check there are no duplicate costs and stop and warn user if not:
  if (any(duplicated(x = costs))) stop("costs cannot include duplicate values.")
  
  # Check costs is not just infinity and stop and warn user if not:
  if (all(costs == Inf)) stop("costs must include at least one non-infinite value.")
  
  # If only one state just return a single zero costmatrix:
  if (length(x = states) == 1) {
    return(
      list(
        make_costmatrix(
          min_state = states,
          max_state = states,
          character_type = "ordered",
          polymorphism_shape = "simplex",
          polymorphism_distance = "euclidean"
        )
      )
    )
  }

  # Create empty costmatrix list:
  costmatrix <- list()
  
  # Set costmatrix size:
  costmatrix$size <- length(x = states)

  # Set cstmatrix type:
  costmatrix$type <- "custom"

  # Build empty costmatrix:
  costmatrix$costmatrix <- matrix(
    data = NA,
    nrow = costmatrix$size,
    ncol = costmatrix$size,
    dimnames = list(states, states)
  )
  
  # Build costmatrix symmetry:
  costmatrix$symmetry <- "Asymmetric"
  
  # Build costmatrix includes_polymorphisms:
  costmatrix$includes_polymorphisms <- FALSE
  
  # Set costmatrix diagonal as all zeroes:
  diag(x = costmatrix$costmatrix) <- 0
  
  # Set costmatrix class as "costMatrix":
  class(costmatrix) <- "costMatrix"
  
  # If only one cost just return a single costmatrix:
  if (length(x = costs) == 1) {
    costmatrix$costmatrix[is.na(x = costmatrix$costmatrix)] <- costs[1]
    costmatrix$symmetry <- "Symmetric"
    return(list(costmatrix))
  }
  
  # Set size of permutation (number of empty costmatrix cells):
  permutation_size <- sum(x = is.na(x = costmatrix$costmatrix))
  
  # Use expand grid to set (starting) permutation number:
  permutations <- as.matrix(x = expand.grid(rep(x = list(costs), times = permutation_size)))
  
  # Remove any permutations where cost ratios duplicate another permutation:
  permutations <- permutations[!duplicated(
    x = apply(
      X = permutations,
      MARGIN = 1,
      FUN = function(i) paste(i / min(x = i), collapse = "%")
    )),
  ]
  
  # Get (starting) permutation size:
  permutations_size <- nrow(x = permutations)
  
  # Convert permutations into costmatrices (may generate duplicates):
  costmatrices <- lapply(
    X = as.list(x = 1:permutations_size),
    FUN = function(i) {
      
      # Start with base costmatrix:
      i_costmatrix <- costmatrix
      
      # Insert permuted scores (to complete costmatrix):
      i_costmatrix$costmatrix[is.na(x = i_costmatrix$costmatrix)] <- unname(obj = permutations[i, ])
      
      # Set satet infinities (i.e., infinite costs for each state row and column):
      state_infinities <- lapply(
        X = as.list(x = states),
        FUN = function(j) rbind(
          row = i_costmatrix$costmatrix[j, ] == Inf,
          column = i_costmatrix$costmatrix[, j] == Inf
        )
      )
      
      # Only proceed if there is at least one infinite cost:
      if (any(unlist(x = state_infinities))) {
        
        # Set infinity violation to FALSE as default (may be updated below):
        infinity_violation <- FALSE
        
        # If any state is isolated the set infinity_violation to TRUE:
        if (any(unlist(x = lapply(X = state_infinities, FUN = function(j) sum(x = j) == ((i_costmatrix$size - 1) * 2))))) infinity_violation <- TRUE
        
        # If more than one state is a forced root state set infinity_violation to TRUE:
        if (sum(unlist(x = lapply(X = state_infinities, FUN = function(j) sum(x = j["column", ]) == (i_costmatrix$size - 1)))) > 1) infinity_violation <- TRUE
        
        # If more than N - 1 states are "to" only set infinity_violation to TRUE:
        row_infinities <- unlist(x = lapply(X = state_infinities, FUN = function(j) sum(x = j["row", ])))
        if (sum(x = row_infinities == (i_costmatrix$size - 1)) >= (i_costmatrix$size - 1) && all(row_infinities) > 0) infinity_violation <- TRUE
        
        # If any infinity violation is found replace infinities with a non-infinite cost (these will ultimately get removed as duplicates):
        if (infinity_violation) i_costmatrix$costmatrix[i_costmatrix$costmatrix == Inf] <- costs[costs != Inf][1]
      }
      
      # Check for symmetry and update if required:
      if (isSymmetric(object = i_costmatrix$costmatrix)) i_costmatrix$symmetry <- "Symmetric"
      
      # Fix costmatrix (ensures path lengths are self-consistent):
      i_costmatrix <- fix_costmatrix(costmatrix = i_costmatrix, message = FALSE)
      
      # Return costmatrix
      i_costmatrix
    }
  )
  
  # Remove any duplicate costmatrices:
  costmatrices <- costmatrices[!duplicated(x = unlist(x = lapply(X = costmatrices, FUN = function(costmatrix) paste(unlist(x = lapply(X = costmatrix, FUN = function(j) paste(as.vector(x = j), collapse = "%"))), collapse = "&"))))]
  
  # Return list of costmatrices:
  return(costmatrices)
}