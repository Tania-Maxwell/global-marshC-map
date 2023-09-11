#' Fold to Index
#' @description Creates index and indexOut for caret::trainControl from a fold vector
#'
#' @param folds vector with fold labels
#'
#' @return list, with index and indexOut
#'
#' @import purrr
#' @import dplyr
#'
#' @export
#'
#' @author Marvin Ludwig
#'
#'
#'

fold2index = function(fold){
  
  fold = data.frame(fold = fold)
  
  indOut = fold %>% dplyr::group_by(fold) %>%
    attr('groups') %>% dplyr::pull(.rows)
  
  ind = purrr::map(seq(length(indOut)), function(x){
    s = seq(nrow(fold))
    s = s[!s %in% indOut[[x]]]
    return(s)
  })
  return(
    list(
      index = ind,
      indexOut = indOut
    )
  )
  
}