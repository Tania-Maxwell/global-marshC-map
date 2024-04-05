plot_pred_0_30 <- function(r){
  nlev <- 200
  my.at <- seq(from = minmax(r)[1],
               to = minmax(r)[2],
               length.out = nlev + 1)
  my.cols <- viridis_pal(option = "D")(nlev)
  
  p <- levelplot(r, margin = FALSE,
                 at = my.at,
                 col.regions = my.cols,
                 main = "SOCS predictions 0-30cm (t ha-1)")
  return(p)
}

plot_pred_30_100 <- function(r){
  nlev <- 200
  my.at <- seq(from = minmax(r)[1],
               to = minmax(r)[2],
               length.out = nlev + 1)
  my.cols <- viridis_pal(option = "D")(nlev)
  
  p <- levelplot(r, margin = FALSE,
                 at = my.at,
                 col.regions = my.cols,
                 main = "SOCS predictions 30-100cm (t ha-1)")
  return(p)
}

plot_aoa_0_30 <- function(r){
  p <- levelplot(r, margin = FALSE, 
                 col.regions =  c("#D55E00","#D55E00","#009E73","#009E73"),
                 at = c(0,0.499, 0.501,1),
                 colorkey=list(at=c(0,0.499, 0.501,1),
                               labels=as.character(c( "0","","", "1"))),
                 main = "Area of applicability 0-30cm")
  return(p)
}

plot_aoa_30_100 <- function(r){
  p <- levelplot(r, margin = FALSE, 
                 col.regions =  c("#D55E00","#D55E00","#009E73","#009E73"),
                 at = c(0,0.499, 0.501,1),
                 colorkey=list(at=c(0,0.499, 0.501,1),
                               labels=as.character(c( "0","","", "1"))),
                 main = "Area of applicability at 30-100cm depth")
  return(p)
}
