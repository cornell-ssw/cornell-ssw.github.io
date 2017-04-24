## Example (language specific): Generalize code?
## One more example using optimization algorithms

data(faithful)

## Look at eruptions
hist(faithful$eruptions, main = "Histogram of Eruptions", xlab = "Eruptions", breaks = 20)


grid_search<-function(bimodal_fn, mu1range, mu2range, xvec){
  mu1_vec = seq(mu1range[1], mu1range[2], by = 0.01)
  mu2_vec = seq(mu2range[1], mu2range[2], by = 0.01)

  mu_mat = matrix(0, nrow = length(mu1_vec), ncol = length(mu2_vec))
  for(i in 1:length(mu1_vec)){
    for(j in 1:length(mu2_vec)){
      mu_mat[i,j] = bimodal_fn(mu1_vec[i], mu2_vec[j], xvec)
    }
  }
  return(list(mu1_vec = mu1_vec, mu2_vec = mu2_vec, mu_mat = mu_mat))
}


compute_bimodal_mixture_fx<-function(mu1, mu2, xvec){
  return(sum(log(exp(-0.5*(xvec - mu1)^2) + exp(-0.5*(xvec - mu2)^2))))
}

show_contour<-function(mu1range, mu2range, xvec, bimodal_fn, opt_type = "nil", muhist = NA, bimodal_dfn = NA, to_compute = "yes", mu_vars = NA){

  # Compute grid
  if(to_compute == "yes"){
    mu_vars = grid_search(bimodal_fn = bimodal_fn, mu1range = mu1range, mu2range = mu2range, xvec = xvec)
  }

  ptitle = paste("Contour plots of mu1 and mu2")

  # Create title based on inputs
  if(opt_type == "CA"){
    ptitle = paste("Coordinate Ascent Steps")
  } else if (opt_type == "arrows") {
    ptitle = paste("Showing direction of gradient")
  } else if (opt_type == "SA") {
    ptitle = paste("Steepest Ascent steps")
  } else if (opt_type == "NR") {
    ptitle = paste("Newton Raphson steps")
  } else if (opt_type != "nil") {
    stop("Wrong opt_type")
  }

  contour(mu_vars$mu1_vec,mu_vars$mu2_vec,mu_vars$mu_mat, main = ptitle, xlab = "mu 1",ylab = "mu 2",cex.lab=1.5,cex.axis=1.5, nlevels = 20) 
  # Draw steps for convergence given various algorithms / parameters for opt_type
  if(opt_type != "nil" && opt_type != "arrows"){
    lines(muhist,type='b',lwd=2,col=2)
  } 
  if (opt_type == "arrows" || opt_type == "SA" || opt_type == "NR"){
    # This function is defined below
    mu1_vec = seq(mu1range[1], mu1range[2], by = 0.01)
    mu2_vec = seq(mu2range[1], mu2range[2], by = 0.01)

    arrow_list = get_arrow_list(mu1range = mu1range, mu2range = mu2range, bimodal_dfn = bimodal_dfn, xvec = xvec)
    arrows(arrow_list$starts[,1],arrow_list$starts[,2],arrow_list$ends[,1],arrow_list$ends[,2],col=4,code=2)
  }
}

show_contour(mu1range = c(2,5), mu2range = c(2,5), bimodal_fn = compute_bimodal_mixture_fx, xvec = faithful$eruptions)

## Generalize 1D to 2D to nD

## An update step 
##
## Input: 
## opt_fn:  A 1D function you want to optimize
## GS_list: A list of optional parameters      
GoldenSection1D_update<-function(opt_fn, GS_list){

  if( (GS_list$x_UB - GS_list$x_mid) > (GS_list$x_mid - GS_list$x_LB) ){  # Working on the right-hand side
    y = GS_list$x_mid + (GS_list$x_UB - GS_list$x_mid)/(1 + GS_list$gr)
    GS_list$f_y = opt_fn(y)
    if( GS_list$f_y > GS_list$y_mid){ 
      GS_list$x_LB = GS_list$x_mid
      GS_list$y_LB = GS_list$y_mid
      GS_list$x_mid = y
      GS_list$y_mid = GS_list$f_y 
    } else { 
      GS_list$x_UB = y
      GS_list$y_UB = GS_list$f_y 
    }
  } else {
    y = GS_list$x_mid - (GS_list$x_mid - GS_list$x_LB)/(1 + GS_list$gr)
    GS_list$f_y = opt_fn(y)
    if( GS_list$f_y > GS_list$y_mid){
      GS_list$x_UB = GS_list$x_mid
      GS_list$y_UB = GS_list$y_mid 
      GS_list$x_mid = y 
      GS_list$y_mid = GS_list$f_y 
    } else { 
      GS_list$x_LB = y
      GS_list$y_LB = GS_list$f_y 
    }
  }
  return(GS_list)
}

## A 1D implementation of GoldenSection
## Input: 
## opt_fn : function to optimize
## x_LB   : "lower bound X"
## x_UB   : "upper bound X"
## tol    : tolerance
## maxit  : max iterations   
GoldenSection1D = function(opt_fn, x_LB, x_UB, tol=1e-8, maxit=100){
  
  # Pre-calculate golden ratio
  gr = (1 + sqrt(5))/2

  x_mid = x_LB + (x_UB-x_LB)/(1+gr)
  # Initialize our list
  GS_list = list(
    gr = gr, 
    x_mid = x_mid,
    x_UB = x_UB,
    x_LB = x_LB,
    y_LB = opt_fn(x_LB),
    y_UB = opt_fn(x_UB),
    y_mid = opt_fn(x_mid),
    f_y = NA
  )
  
  tol.met = FALSE    # No tolerance met
  iter = 0           # No iterations

  # Also, note that while while(1) is discouraged,
  # tol.met = TRUE below is the same as "break"

  while(!tol.met){
    iter = iter + 1
    GS_list = GoldenSection1D_update(opt_fn = opt_fn, GS_list = GS_list)
    if( (GS_list$x_UB - GS_list$x_mid) < tol || iter > maxit ){ 
      tol.met=TRUE 
    }
  }
  return(list(x_mid = GS_list$x_mid, iter = iter))
}

## This is for 1D. What if we wanted to use this
## in conjunction with multiple dimensions?
##
## Eg, LASSO ; using coordinate ascent

## Coordinate Ascent:
## Want to optimize f(mu_1, mu_2, mu_3, .., mu_n)
## While {convergence criteria not met}
##   for j in 1:n
##     Hold mu_i constant for i \neq j
##     Find mu_j that optimizes f(..., mu_j, ..)
##     Update mu_j
##
## 
## To find mu_j that optimizes f(...,mu_j, ..)
## can use any 1D algorithm
##
## Suppose we are given GoldenSection as above
## Note that it takes in a function with only one
## input
##
## What's the "best" way to make changes to prevent
## errors?


## Demonstrate with bimodal mixture model

# Previous
compute_bimodal_mixture_fx_old<-function(mu1, mu2, xvec){
  return(sum(log(exp(-0.5*(xvec - mu1)^2) + exp(-0.5*(xvec - mu2)^2))))
}

# Now
compute_bimodal_mixture_fx_new<-function(mu, xvec, opt_para_pos){
  
  m1 = mu[1]
  m2 = mu[2]
  xvec = xvec

  if (opt_para_pos == 1){
    return(
      function(opt_para){
        return(sum(log(exp(-0.5*(xvec - opt_para)^2) + exp(-0.5*(xvec - m2)^2))))
      }
    )
  } else if (opt_para_pos == 2) {
    return(
      function(opt_para){
        return(sum(log(exp(-0.5*(xvec - m1)^2) + exp(-0.5*(xvec - opt_para)^2))))
      }
    )
  }
}

compute_bimodal_mixture_fx(mu = c(1,2), xvec = faithful$eruptions, opt_para_pos = 1 )
compute_bimodal_mixture_fx(mu = c(1,2), xvec = faithful$eruptions, opt_para_pos = 2 )


# and try this
compute_bimodal_mixture_fx(mu = c(1,2), xvec = faithful$eruptions, opt_para_pos = 1 )(1)
compute_bimodal_mixture_fx(mu = c(1,2), xvec = faithful$eruptions, opt_para_pos = 2 )(2)


CoordinateAscent<-function(mu, x_LB_vec , x_UB_vec , bimodal_fn , xvec , tol=1e-8, maxit=1000){

  iter = 0              # Initialization
  tol.met = FALSE
  muhist = matrix(0,nrow = maxit+1, ncol = 2)
  muhist[1,] = mu

  while(!tol.met){  # Tolerance will be checked by how much we move mu
    oldmu = mu      # over one cycle accross the dimensions.
    
    for(ndims in 1:length(mu)){  
      iter = iter + 1     
      mu[ndims] = GoldenSection1D(opt_fn = bimodal_fn(mu = mu, xvec = xvec, opt_para_pos = ndims), x_LB = x_LB_vec[ndims], x_UB = x_UB_vec[ndims])$x_mid
      muhist[iter+1,] = mu
    }

    if( max(abs(mu - oldmu))<tol | iter > maxit){ 
      tol.met = TRUE
      muhist = muhist[1:(iter+1),]
    } else { 
      oldmu = mu 
    }
  } 
  return(list(mu = mu, iter = iter, muhist = muhist))
}


CA_res = CoordinateAscent(mu = c(3.6,3.5), x_LB_vec = c(1,3.5), x_UB_vec = c(4,5.5), bimodal_fn = compute_bimodal_mixture_fx_new, xvec = faithful$eruptions)


show_contour(mu1range = c(2.5,5), mu2range = c(2.5,5), bimodal_fn = compute_bimodal_mixture_fx_old, xvec = faithful$eruptions, opt_type = "CA", muhist = CA_res$muhist)

