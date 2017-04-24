## A function to compute roots with
## the Secant Method


## Inputs:
##  x0      -> first starting point
##  x1      -> second starting point
##  fnx     -> function to find root of
##  WUSF    -> an update step function
##  bds     -> for plots 
##  epsilon -> tolerance
##  maxiter -> max iterations
##  type    -> type of update function

Secant_With_Readline<-function(x0, x1, fnx, wrong_update_step_fn, bds, epsilon = 1e-8, maxiter = 100, type = 1){
  iter = 1

  
  xvec = seq(min(bds[1],x0,x1), max(bds[2],x0,x1), length.out = 1000)
  yvec = fnx(xvec)
  plot(xvec,yvec$val,type = "l", ylab = "", xlab = "", 
    main = paste("Initial plot of", yvec$name),col = "blue")

  ## axis
  abline(h = 0)
  readline("Pause to check graph")

  # Draw secants
  f1 = fnx(x1)$val
  f0 = fnx(x0)$val
  m = (f0 -f1)/(x0-x1)
  c = f0 - m*x0
  
  x_prev = x1
  x_now = wrong_update_step_fn(x0 = x0, x1 = x1, fnx = fnx, type = type)
  abline(a = c, b = m, col = "red")
  abline(v = x_now, lty = 2)
  f_now = fnx(x_now)$val
  lines(x_now,f_now, type = "p", pch = 4)
  
  readline("Pause to check graph")

  while(1){
    x_tmp = x_now
    x_now = wrong_update_step_fn(x0 = x_prev, x1 = x_now, fnx = fnx, type = type)
    x_prev = x_tmp
    
    y_now = fnx(x_now)$val
    
    # Plot the new graph
    xvec = seq(min(bds[1],x_prev,x_now), max(bds[2],x_prev,x_now), length.out = 1000)
    yvec = fnx(xvec)
    plot(xvec,yvec$val,type = "l", ylab = "", xlab = "", 
    main = paste("Updated plot of", yvec$name, "root at:", x_now),col = "blue")
    abline(h = 0)
    
    f1 = fnx(x_now)$val
    f0 = fnx(x_prev)$val
    m = (f0 -f1)/(x_prev-x_now)
    c = f0 - m*x_prev
    abline(a = c, b = m, col = "red")
    abline(v = x_now, lty = 2)
    lines(x_now,y_now, type = "p", pch = 4)
    readline("Pause to check graph")
    if (abs(x_now - x_prev) < epsilon){
      break
    }    
    if (iter > maxiter){
      break
    }  
    iter = iter + 1
  }
  return(x_now)
}


wrong_update_step_fn<-function(x0, x1, fnx, type = 1){
  if(type == 1){
    return(x1 - fnx(x1)$val * (x1 - x0)/(fnx(x1)$val - fnx(x0)$val))
  } else if (type == 2){
    return(x1 - fnx(x0)$val * (x1 - x0)/(fnx(x1)$val - fnx(x0)$val))
  } else if (type == 3){
    return(x0 - fnx(x0)$val * (x1 - x0)/(fnx(x1)$val - fnx(x0)$val))
  } else if (type == 4){
    return(x0 - fnx(x1)$val * (x1 - x0)/(fnx(x1)$val - fnx(x0)$val))
  }
}


## A function
## (nice to have some metadata for generic fn names)
fnx<-function(x){
  name = "x*cos(x)"
  val = x*cos(x)
  return(list(name = name, val = val))
}

## Let's look at different types

Secant_With_Readline(x0 = 1, x1 = 1.2, fnx = fnx, wrong_update_step_fn = wrong_update_step_fn, bds = c(-5,5), type = 1)
