
## Integrate function so...
make_integrate_plot<-function(n){
  true_val = rep(0, n+1)
  rec_val = rep(0, n+1)
  MC_val = rep(0, n+1)
  
  # this is slow, but mehhh
  for(j in 0:n){
    true_val[j +1] =  integrate(function(x) {return(x^j * exp(x))}, lower = 0, upper = 1)$value
  }
  
  rec_val[1] = exp(1) - 1
  rec_val[2] = 1
  for(j in 2:n){
    rec_val[j+1] = exp(1) - (j)*rec_val[j]
  }
  
  # a silly idea
  evals = runif(n = 1000000)
  MC_val[1] = exp(1) -1
  for(j in 1:n){
    MC_val[j+1] = mean(evals^j * exp(evals))
  }
  rm(evals)

  par(mfrow = c(2,2))
  plot(0, type = "n", main = "Plot of integral with respect to n", xlim = c(1,20), ylim = c(0,1), xlab = "Value of n", ylab = "Value of y(n)")

  lines(1:20, true_val[2:21], col = "black")
  lines(1:20, MC_val[2:21], col = "blue", lty = 2)
  lines(1:20, rec_val[2:21], col = "red", lty = 2)
  legend("top", legend = c("Actual", "MC Integral", "Recursion"), lty = c(1,2,2), col = c("black", "blue","red"))

  plot(0, type = "n", main = "Plot of integral with respect to n", xlim = c(1,20), ylim = c(0,1), xlab = "Value of n", ylab = "Value of y(n)")

  lines(1:20, true_val[2:21], col = "black")

  plot(0, type = "n", main = "Plot of integral with respect to n", xlim = c(1,20), ylim = c(0,1), xlab = "Value of n", ylab = "Value of y(n)")

  lines(1:20, MC_val[2:21], col = "blue", lty = 2)

  plot(0, type = "n", main = "Plot of integral with respect to n", xlim = c(1,20), ylim = c(0,1), xlab = "Value of n", ylab = "Value of y(n)")

  lines(1:20, rec_val[2:21], col = "red", lty = 2)

}

