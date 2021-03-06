#####     Auxiliar Generic Functions     #####

deriv_num <- function(fun,x,h=1e-5) {
  # function for two-sided numerical derivation
  ( fun(x+h)-fun(x-h) ) / (2*h)
}

bucket <- function( x, x_i ) {
  # this function returns the interval in which x is located corresponding with the values of x_i
  # 0 if x < x_i[1]
  # 1 if x >=  x_i[1]  and x < x_i[2]
  # ...
  # j if x >=  x_i[j]  and x < x_i[j+1]
  # ...
  # k if x >= x_i[k]
  
  x_i_mat <- matrix(x_i,length(x),length(x_i),byrow=T)
  c1 <- cbind( T, x >= x_i_mat )
  c2 <- cbind( x < x_i_mat , T )
  b <- rep(0:length(x_i),length(x))[as.vector(t(c1 & c2))]
  return( b )
}




####   S3 class definition   ###

# Constructor #

# Creates the objects that contains the necesary information to get our sample
as.abscissae <- function( x, f, l_h, u_h, eps ) {
  if ( is.expression(f) ) {
    f <- eval(parse(text=paste( "function(x) {",as.character(f),"}" )))
  }
  if (!is.function(f)) {
    stop( '"f" has to be either expression or function in terms of "x"' )
  }
  h <- function(x){ log(f(x)) }
  
  T_k <- x
  
  h_T <-  h(T_k)
  
  hp_T <- ( h(T_k+eps) - h_T ) / eps
  hp_T <- round(hp_T,10)
  
  k <- length(T_k)
  abscissae <- structure(
    list(
      f=f,
      T_k=T_k,
      h_T=h_T,
      hp_T=hp_T,
      z_i=NULL,
      k=k,
      l_h=l_h,
      u_h=u_h )
    , class = "abscissae"
  )
  return(abscissae)
}




#####     Methods for "abscissae" S3 class     #####

get_zi <- function (x, ...) UseMethod("get_zi")
get_zi.abscissae <- function(x) {
  #browser()
  T_k <- x$T_k
  h_T <-  x$h_T
  hp_T <- x$hp_T
  k <- length(T_k)
  z_i <- ( h_T[-1] - h_T[-k] - T_k[-1] * hp_T[-1] + T_k[-k] * hp_T[-k] ) / (hp_T[-k]-hp_T[-1])
  if( all(hp_T==hp_T[1]) ) { z_i <- (T_k[-1] + T_k[-k])/2 } # in case of exponential, we can continue simulation by defining zi in the middle of Tk's
  if( any(is.na(z_i)|is.nan(z_i)) ) { stop("Some elements of z_i could not be calculated") }
  z_i <- c(x$l_h,z_i,x$u_h)
  x$z_i <- z_i
  return(x)
}


check <- function (x, ...) UseMethod("check")
check.abscissae <-function(abscissae) {
  #check.abscissae is a method that takes as an input the abscissae at any 
  #iteration and checks that certain criterion are met.
  #The checks are the following:
  #Check 1: (error) x must have length greater than or equal to 2.
  #Check 2: (error) x must contain unique elements.
  #Check 3: (warning) The upper bound must be greater than the lower bound.
  #Check 4: (error) Values of x must be within the upper and lower bounds.
  
  #Check 9: (error) Verify z_i is not empty.
  #Check 10: (error) Verify dimensions of T_k and z_i are correct. z_i must 
  #          always have one more element the T_k.
  
  #Check 5: (error) Values of x must have mass in f, or h will not be finite.
  #Check 6: (warning) Some values of x won't be used if h at that x is infinite,
  #         but Check 1 must still hold.
  #Check 7: (error) Where there is a global max on the domain of h, 
  #         there must be at least one point on either side of the max.
  #Check 8: (error) A naive check for concavity of h by checking derivates at bounds,
  #         where bounds are finite.
  
  T_k <- abscissae$T_k
  h_T <-  abscissae$h_T
  hp_T <- abscissae$hp_T
  bound <- c(abscissae$l_h,abscissae$u_h)
  
  f <- abscissae$f
  h <- function(x){ log(f(x)) }
  ep <- 1e-3
  
  #Check 1
  if(length(T_k) < 2){stop("x must be a vector of length 2 or more")}
  
  #Check 2
  for(i in 1:(length(T_k) - 1)){
    for(j in (i + 1):length(T_k)){
      if(is.logical(all.equal(T_k[i], T_k[j]))){stop("x must be a vector of unique points.")}
    }
  }
  
  #Check 3
  if(bound[1] > bound[2]){
    warning("Upper bound must be greater than Lower bound")
    LB <- bound[order(bound)[1]]
    UB <- bound[order(bound)[2]]
  }
  else{LB <- bound[1]; UB <- bound[2]}
  
  #Check 4
  if(sum(T_k > UB) > 0 | sum(T_k < LB) > 0){stop("x's must be chosen between the prescribed bounds")}
  
  #Check 9
  if(is.null(abscissae$z_i)){stop("z_i is not defined.")}
  
  #Check 10
  if(length(abscissae$z_i) != length(abscissae$T_k) + 1){stop("The dimension of the z_i or T_k is incorrect.")}
  
  T_k <- T_k[which(is.infinite(h_T) == F)]
  h_T <- h_T[which(is.infinite(h_T) == F)]
  hp_T <- hp_T[which(is.infinite(h_T) == F)]
  
  #Check 5
  if(length(T_k) < 2){stop("Please input different x such that f has more mass at x.")}
  
  #Check 6
  # if(length(T_k) != length(init_val)){warning("One or more of the intitial points weren't used.")}
  
  k <- length(T_k)
  
  #Check 7
  if(is.infinite(LB) && is.infinite(UB)){
    i <- 1
    while(prod(hp_T[i], hp_T[i + 1]) > 0 && i < length(T_k)){
      i <- i + 1
    }
    if(i == length(T_k)){stop("Choose x's such that they straddle the mode of f or choose more appropriate bounds.")}
  }
  if(!is.infinite(LB) && is.infinite(UB)){
    h_LB <- h(LB)
    if(!is.infinite(h_LB)){
      hp_LB <- ( h(LB + ep) - h_LB ) / ep
    }
    else{hp_LB <- 1}
    if(hp_LB > 0){
      i <- 1
      while(prod(hp_T[i], hp_T[i + 1]) > 0 && i < length(T_k)){
        i <- i + 1
      }
      if(i == length(T_k)){stop("Choose x's such that they straddle the mode of f or choose more appropriate bounds.")}
    }
  }
  if(is.infinite(LB) && !is.infinite(UB)){
    h_UB <- h(UB)
    if(!is.infinite(h_UB)){
      hp_UB <- ( h(UB + ep) - h_UB ) / ep 
    }
    else{hp_UB <- -1}
    if(hp_UB < 0){
      i <- 1
      while(prod(hp_T[i], hp_T[i + 1]) > 0 && i < length(T_k)){
        i <- i + 1
      }
      if(i == length(T_k)){stop("Choose x's such that they straddle the mode of f or choose more appropriate bounds.")}
    }
  }
  if(!is.infinite(LB) && !is.infinite(UB)){
    h_LB <- h(LB)
    h_UB <- h(UB)
    if(!is.infinite(h_LB)){
      hp_LB <- ( h(LB + ep) - h_LB ) / ep 
    }
    else{hp_LB <- 1}
    if(!is.infinite(h_UB)){
      hp_UB <- ( h(UB + ep) - h_UB ) / ep 
    }
    else{hp_UB <- -1}
    if(hp_LB > 0 && hp_UB < 0){
      i <- 1
      while(prod(hp_T[i], hp_T[i + 1]) > 0 && i < length(T_k)){
        i <- i + 1
      }
      if(i == length(T_k)){stop("Choose x's such that they straddle the mode of f or choose more appropriate bounds.")}
    }
    
    #Check 8
    if(hp_LB < 0 && hp_UB > 0){stop("f is not log concave!")}
  }
  
}

plot.abscissae <- function(abscissae, plot.h=F) {
  
  if (plot.h) {
    f <- abscissae$f
    h <- function(x){ log(f(x)) }
  }
  def.par <- par(no.readonly = TRUE) # save default, for resetting...
  par(mar=c(2,2,2,2))
  layout(matrix(c(1,1:3),2,2,byrow=T))
  
  k <- length(abscissae$T_k)
  
  if(abscissae$z_i[1]!=-Inf) {limx1 <- abscissae$z_i[1]} else {limx1 <- abscissae$z_i[2]}
  if(abscissae$z_i[k+1]!=Inf) {limx2 <- abscissae$z_i[k+1]} else {limx2 <- abscissae$z_i[k]}
  
  curve( u(x,abscissae), limx1,limx2, col="red", main="Upper and Lower functions" )
  curve( l(x,abscissae), abscissae$T_k[1], abscissae$T_k[k], col="blue", add=T )
  if (plot.h) {
    curve( h(x), limx1, limx2, add=T, col="black" )
    legend("topright",legend=c("u(x)","h(x)","l(x)"),bty="n",col=c("red","black","blue"),bg="white",lty=1)
  } else {
    legend("topright",legend=c("u(x)","l(x)"),bty="n",col=c("red","blue"),bg="white",lty=1)
  }
  
  curve( s(x,abscissae), limx1, limx2, col="red", main="Sampling pdf" )
  if (plot.h) {
    curve( f(x), limx1, limx2, add=T, col="black" )
    legend("topright",legend=c("s(x)","f(x)"),bty="n",col=c("red","black"),bg="white",lty=1)
  } else {
    legend("topright",legend=c("s(x)"),bty="n",col=c("red"),bg="white",lty=1)
  }
  
  curve( S(x,abscissae), limx1, limx2, col="red", main="Sampling cdf")
  abline( v=abscissae$T_k, lty=2 )
  legend("topright",legend=c("S(x)"),bty="n",col=c("red"),bg="white",lty=1)
  
  #curve( S_inv.abscissae( x , abscissae ) , 0.01, 0.99, main="Inverse cdf", col="blue")
  
  par(def.par) # reseting plot parameters
}

add_points <- function (x, ...) UseMethod("add_points")
add_points.abscissae <- function(x,new_T_k,new_h_T,new_hp_T) {
  new_order <- order(c(x$T_k,new_T_k))
  x$T_k <- c(x$T_k,new_T_k)[new_order]
  x$h_T <- c(x$h_T,new_h_T)[new_order]
  x$hp_T <- c(x$hp_T,new_hp_T)[new_order]
  x$k <- length(x$T_k)
  x$z_i <- NULL
  return(x)
}




#####     Functions using "abscissae" S3 class     #####

l <- function( x, abscissae ) {
  #browser()
  if( class(abscissae)!="abscissae" ) { stop('"abscissae" has to be an object of that class') }
  
  T_k <- abscissae$T_k
  h_T <- abscissae$h_T
  j <- bucket( x , T_k )
  l_notdef <- x<min(T_k)|x>max(T_k)
  j[l_notdef] <- 1
  l <- ( (T_k[j+1]-x)*h_T[j] + (x-T_k[j])*h_T[j+1] ) / (T_k[j+1]-T_k[j])
  l[l_notdef] <- -Inf
  return( l )
}

u <- function( x , abscissae ) {
  #browser()
  if( class(abscissae)!="abscissae" ) { stop('"abscissae" has to be an object of that class') }
  
  T_k <- abscissae$T_k
  h_T <- abscissae$h_T
  hp_T <- abscissae$hp_T
  z_i <- abscissae$z_i
  
  k <- length(T_k)
  j <- bucket( x , z_i )
  j[x==z_i[length(z_i)]] <- j[x==z_i[length(z_i)]] - 1 #  we would evaluate u(z_k) in the last line segment, to be well defined
  u <- h_T[j] + (x-T_k[j])*hp_T[j]
  return( u )
}

int_s <- function( abscissae ) {
  # browser()
  if( class(abscissae)!="abscissae" ) { stop('"abscissae" has to be an object of that class') }
  
  T_k <- abscissae$T_k
  h_T <- abscissae$h_T
  hp_T <- abscissae$hp_T
  z_i <- abscissae$z_i
  k <- length(T_k)
  sum(
    (1/hp_T) * ( exp( u(z_i[-1],abscissae) ) - exp( u(z_i[-(k+1)],abscissae) ) )
  )
}

s <- function( x, abscissae ) {
  T_k <- abscissae$T_k
  h_T <- abscissae$h_T
  hp_T <- abscissae$hp_T
  z_i <- abscissae$z_i
  (1/int_s( abscissae )) * exp( u( x, abscissae ) )
}

S <- function( x , abscissae ) {
  # browser()
  T_k <- abscissae$T_k
  h_T <- abscissae$h_T
  hp_T <- abscissae$hp_T
  z_i <- abscissae$z_i
  
  # gives the interval of each x, corresponding with the segments of lines
  k <- length(T_k)
  
  j <- bucket( x , z_i )
  j[x==z_i[length(z_i)]] <- j[x==z_i[length(z_i)]] - 1 #  we would evaluate u(z_k) in the last line segment, to be well defined
  
  #k <- length(T_k)
  # vector with integral of exp-trapeziods areas
  int_trap <- (1/hp_T) * ( exp( u(z_i[-1], abscissae) ) - exp( u(z_i[-(k+1)], abscissae) ) )
  
  # for each x, calculate the area of the trapezoids before z_j-i
  int_trap_mat <- matrix(int_trap,length(x),length(int_trap),byrow=T)
  j_mat <- matrix(j,length(x),length(int_trap))
  int_mat <- matrix(1:length(int_trap),length(x),length(int_trap),byrow=T)
  int_trap_mat[ int_mat >= j_mat ] <- 0
  int_bef <- apply( int_trap_mat ,1,sum)
  
  cdf <- (1/int_s( abscissae )) * ( int_bef + (1/hp_T[j]) * ( exp( u(x, abscissae) ) - exp( u(z_i[j], abscissae) ) ) )
  return(cdf)
}

S_inv <- function( x , abscissae ) {
  #browser()
  if( class(abscissae)!="abscissae" ) { stop('"abscissae" has to be an object of that class') }
  
  if( any(x<0|x>1) ) { stop("Some values of x are <0 or >1") }
  
  T_k <- abscissae$T_k
  h_T <- abscissae$h_T
  hp_T <- abscissae$hp_T
  z_i <- abscissae$z_i
  
  k <- length(T_k)
  
  j <- bucket( x,
               S( x=z_i, abscissae )
  )
  j[x==0] <- 1
  j[x==1] <- length(T_k)
  
  # vector with integral of exp-trapeziods areas
  int_trap <- (1/hp_T) * ( exp( u( x=z_i[-1], abscissae ) ) - exp( u( x=z_i[-(k+1)], abscissae) ) )
  
  # for each x, calculate the area of the trapezoids before z_j-i
  int_trap_mat <- matrix(int_trap,length(x),length(int_trap),byrow=T)
  j_mat <- matrix(j,length(x),length(int_trap))
  int_mat <- matrix(1:length(int_trap),length(x),length(int_trap),byrow=T)
  int_trap_mat[ int_mat >= j_mat ] <- 0
  int_bef <- apply( int_trap_mat ,1,sum)
  
  cdf_inf <- ( log( hp_T[j] * ( x * int_s( abscissae ) - int_bef ) + exp( u(x=z_i[j], abscissae) ) )  - h_T[j] )/hp_T[j] + T_k[j]
  return(cdf_inf)
}

#The following function performs a non-parametric test (permutation test)
#which tests for a difference in distributions. We will use it to test
#for difference between the ARS sample distribution and the theoretical
#distribution. The p-value returned is small if the distributions are 
#not the same.
permdiff = function(x,y,B){
  k = mean(x) - mean(y)
  P_Stat = numeric(B)
  for (b in 1:B){
    m = length(x)
    z = c(x, y)
    Ind = sample(length(z))
    P_Stat[b] = mean(z[Ind[1:m]])-mean(z[Ind[-(1:m)]])
  }
  R = sum(P_Stat >= k)
  p = R/(B + 1)
  return(p)
}

test <- function(B, f, init_val, l_f, u_f, rdensity, ddensity, eps = 1e-3, leg="Density", ...){
  
  #The following function samples from the desired distribution using 
  #the ARS algorithm and then samples from the distribution using random 
  #number generator functions in R. It performs a permutation test on
  #the two samples to check for the similarity between distributions.
  #It returns the two samples, the means of each sample and the p-value
  #from the permutation test.
  
  #browser()
  samp_ars <- ars(B, f, l_f, u_f, init_val)
  samp_theo <- rdensity(B,...)
  m_ars <- mean(samp_ars)
  m_theo <- mean(samp_theo)
  mean <- c(m_ars, m_theo)
  names(mean) <- c("ARS Sample", "Theoretical Sample")
  p <- permdiff(samp_ars, samp_theo, 2000)
  ARS <- list(samp_ars, samp_theo, mean, p)
  names(ARS) <- c("ARS Sample", "Theoretical Sample", "Means", "p-value")
  hist(samp_ars, freq = F, col = "grey95", main = "Density", xlab = "ARS Sample")
  legend("topright",legend=leg,bty="n")
  density <- function(x){ ddensity(x, ...)}
  curve(density, add = T, col = "blue" )
  print("Non-parametric Permutation Test results:")
  print(ARS[["Means"]])
  print(paste("p-value",ARS[["p-value"]]))
  return(ARS)
}

#####     Adaptative rejecting sampling method     #####

ars <- function( B=100, f ,l_f=-Inf, u_f=Inf, init_abs=NULL, eps=1e-4 , m="exp", rej_evol.pdf=NULL, abs_evol.pdf=NULL, hist.pdf=NULL ) {
  # require(ars_243)
  # browser()
  if ( is.expression(f) ) {
    f_exp <- f
    f <- function(x) { eval(f_exp) }
  }
  if (!is.function(f)) {
    stop( '"f" has to be either expr or function' )
  }

  h <- function(x){ log(f(x)) }

  # Initial Points
  if (is.null(init_abs)) {
    abscissae <- init_abs( h, l_h=l_f, u_h=u_f)
  } else {
    abscissae <- as.abscissae( init_abs, f, l_h=l_f, u_h=u_f, eps=eps )
  }
  #check(abscissae)
  abscissae <- get_zi( abscissae )
  check(abscissae)
  
  #####     Simulation     #####
  
  sim_values <- as.numeric(NULL)
  # Numbers of points tested on each iteration
  iter <- 0
  
  def.par <- par(no.readonly = TRUE) # save default plot settings, for resetting...
  dev_orig <- dev.list()
    
  if( !is.null(rej_evol.pdf) ) {
    pdf(file=rej_evol.pdf,width=10, height=7, onefile=T)
    dev_rej <- dev.cur()
  }
  
  if( !is.null(abs_evol.pdf) ) {
    pdf(file=abs_evol.pdf,width=10, height=7, onefile=T)
    dev_abs <- dev.cur()
  }
  
  m_orig <- m
  while (length(sim_values)<B) {
  #while (iter<10) {
    iter <- iter + 1
    #print(iter)
    
    if(m_orig=="exp") { m<-2^iter }
    if(m_orig=="lin") { m<-2*iter }
    suppressWarnings( m <- as.numeric(m) )
    if( is.na(m) ) {stop('"m" has to be either a number or any of "exp", or "lin"')}
    
    if( !is.null(abs_evol.pdf) ) {
      dev.set(dev_abs)
      plot( abscissae, plot.h=T )
    }
    
    # sampling uniform for rejection sampling
    w <- runif(m,0,1)
    
    # sampling from s(x)
    x_star <- S_inv( runif(m,0,1) , abscissae )
    #browser()
    ### Testing sample ###
    # (1) squeezing test
      accept_1 <- ( w <= exp( l(x_star,abscissae) - u(x_star,abscissae) ) )
      #accept_1[is.na(accept_1)] <- F # those sampled values not defined in l(x)
      if (any(accept_1)) {
        sim_values <- c(sim_values,x_star[accept_1])
      }
    
    # limits for graphics
    k <- length(abscissae$T_k)
    if(abscissae$z_i[1]!=-Inf) {limx1 <- abscissae$z_i[1]} else {limx1 <- abscissae$z_i[2]}
    if(abscissae$z_i[k+1]!=Inf) {limx2 <- abscissae$z_i[k+1]} else {limx2 <- abscissae$z_i[k]}
    
    # Plot accepted points in phase 1
    if( !is.null(rej_evol.pdf) ) {
      dev.set(dev_rej)
      layout(matrix(1:2))
      par(mar=c(0,0,0,0)+2)
      
      curve(f(x),limx1,limx2,main="f(x) and s(x)",col="black")
      curve(s(x,abscissae),limx1,limx2,col="red",add=T,lty=2)
      legend("topright",legend=c("s(x)","f(x)"),col=c("red","black"),bg="white",lty=c(2,1))
      
      curve( exp( h(x) - u(x,abscissae) ) ,
             limx1, limx2, col="darkgreen", lty=1, main="Squeezing and Rejection areas", ylim=c(0,1), ylab="" )
      curve( exp( l(x,abscissae) - u(x,abscissae)),
             min(abscissae$T_k), max(abscissae$T_k), col=rgb(0,200,0,maxColorValue=256), lty=2, lwd=1.5, add=T)
      abline(v=abscissae$z_i,col="orange",lty=3)
      points(x=x_star[accept_1],w[accept_1],col="green",pch=19)
      legend("left",legend=c("phase 1","phase 2","rejected"),col=c("green","gold","red"),bg="white",pch=19)
      legend("right",legend=c("exp(h(x)-u(x))","exp(l(x)-u(x))","z_i"),col=c("darkgreen",rgb(0,200,0,maxColorValue=256),"orange"),bg="white",lty=c(1,2,3))
    }

    ### Testing sample ###
    # (2) rejection test
    
    if( any(!accept_1) ) {
      new_T_k <- x_star[!accept_1]
      new_h_T <-  h(new_T_k)
      new_hp_T <- round( ( h(new_T_k+eps) - new_h_T ) / eps , 10 )
      
      accept_2 <- ( w[!accept_1] <= exp( new_h_T - u(new_T_k,abscissae) ) )
      if (any(accept_2)) {
        sim_values <- c(sim_values,new_T_k[accept_2])
      }

      # Plot of accepted and rejected points in phase 1 or 2
      if( !is.null(rej_evol.pdf) ) {
        points(x=x_star[!accept_1][accept_2],w[!accept_1][accept_2],col="gold",pch=19)
        points(x=x_star[!accept_1][!accept_2],y=w[!accept_1][!accept_2],col="red",pch=19)
      }
      # Add to abscissae those point evaluated in h(x)
      abscissae <- add_points.abscissae( abscissae, new_T_k, new_h_T, new_hp_T )
      abscissae <- get_zi( abscissae )
      check( abscissae )
    }
    
  }

  sim_values <- sim_values[1:B]
  
  if( !is.null(rej_evol.pdf) ) {
    dev.off(dev_rej)
  }
  if( !is.null(abs_evol.pdf) ) {
    dev.off(dev_abs)
  }
  
  if( !is.null(hist.pdf) ) {
    pdf(file=hist.pdf,width=10, height=7, onefile=T)
    hist(sim_values,col="grey95",breaks=20)
    dev.off()
  }
  suppressWarnings( par(def.par) ) # reset plot settings to default
  
  return( sim_values )
}




#####     EXAMPLES: ars()     #####

# Normal distribution
set.seed(0)
mu <- 5
sigma <- 2
ars( B=1000,
     #f=function(x) {dnorm(x,mu,sigma)},
     f=expression( (2*pi*sigma^2)^(-1/2) * exp(-(x-mu)^2/(2*sigma^2)) ),
     l_f=-Inf,
     u_f=Inf,
     init_abs=seq(0,6,1),
     m="exp",
     rej_evol.pdf= "rej_normal.pdf",
     abs_evol.pdf= "abs_normal.pdf",
     hist.pdf = "hist_normal.pdf"
)

# Truncated normal distribution
set.seed(0)
mu <- 5
sigma <- 2
ars( B=1000,
     #f=function(x) {dnorm(x,mu,sigma)},
     f=expression( (2*pi*sigma^2)^(-1/2) * exp(-(x-mu)^2/(2*sigma^2)) ),
     l_f=-2,
     u_f=7,
     init_abs=seq(3,6,1),
     m="exp",
     rej_evol.pdf= "rej_normal_trunc.pdf",
     abs_evol.pdf= "abs_normal_trunc.pdf",
     hist.pdf = "hist_normal_trunc.pdf"
)


# Beta distribution
set.seed(0)
a <- 2
b <- 2
ars( B=1000,
     f=function(x) {dbeta(x,a,b)},
     #f=expression( (gamma(a+b)/(gamma(a)*gamma(b))) * x^(a-1) * (1-x)^(b-1) ),
     l_f=0,
     u_f=1,
     init_abs=seq(0.1,0.9,0.2),
     m="exp",
     rej_evol.pdf= "rej_beta.pdf",
     abs_evol.pdf= "abs_beta.pdf",
     hist.pdf = "hist_beta.pdf"
)


# Exponential distribution
set.seed(0)
lambda <- 2
ars( B=1000,
     f=function(x) {dexp(x,lambda)},
     #f=expression( lambda * exp(- lambda * x) ),
     l_f=0,
     u_f=Inf,
     init_abs=seq(1,5,1),
     m="exp",
     rej_evol.pdf= "rej_exp.pdf",
     abs_evol.pdf= "abs_exp.pdf",
     hist.pdf = "hist_exp.pdf"
)



# Gamma distribution
set.seed(0)
r <- 5
lambda <- 2
ars( B=1000,
     #f=function(x) {dgamma(x,shape=r,rate=lambda)},
     f=expression( (lambda^r)/gamma(r) * x^(r-1) * exp(- lambda * x) ),
     l_f=0,
     u_f=Inf,
     init_abs=seq(1,5,1),
     m="exp",
     rej_evol.pdf= "rej_gamma.pdf",
     abs_evol.pdf= "abs_gamma.pdf",
     hist.pdf = "hist_gamma.pdf"
)


#####     EXAMPLES: test()     #####

require('VGAM')

B<-1000

# Normal distribution
mu <- 5
sigma <- 2
test_Normal <- test(
  B,
  f=expression( (2*pi*sigma^2)^(-1/2) * exp(-(x-mu)^2/(2*sigma^2)) ),
  #f=function(x) {dnorm(x,mu,sigma)},
  init_val=c(-10, 3, 4, 6, 15),
  l_f=-Inf,
  u_f=Inf,
  rdensity=rnorm,
  ddensity=dnorm,
  mean = mu, sd = sigma,
  leg = "Normal"
)


# Beta distribution
a <- 5
b <- 2
test_B <- test(
  B,
  f=function(x) {dbeta(x,a,b)},
  init_val=c(.4, .6, .9),
  l_f=0,
  u_f=1,
  rbeta,
  dbeta,
  shape1 = a,
  shape2 = b,
  ep = ep,
  leg = "Beta"
)

# Gamma distribution
r=15
lambda=1
init_val <- 
  test_Gm <- test(
    B,
    f=function(x) {dgamma(x,r,lambda)},
    init_val=c(5, 10, 15, 20, 25, 40),
    l_f=0,
    u_f=Inf,
    rgamma,
    dgamma,
    shape = r,
    rate = lambda,
    leg = "Gamma"
  )

if(T) {
  # Chi-Square distribution
  d_f <- 10
  f <- function(x) { dchisq(x, d_f) }
  l_f = 0
  u_f = Inf
  init_val <- c(3, 5, 10, 15, 20, 25)
  test_Ch <- test(B, f, init_val, l_f, u_f, rchisq, dchisq, df = d_f, leg = "Chi-Square")
  test_Ch$Means
  test_Ch$`p-value`
}
if(T) {
  # Exponential distribution
  lambda <- .1
  f <- function(x) { dexp(x, lambda)}
  l_f = 0
  u_f = Inf
  init_val <- c(1.5, 2, 2.5, 3, 10, 20, 40)
  test_E <- test(B, f, init_val, l_f, u_f, rexp, dexp, rate = lambda, leg = "Exponential")
  test_E$Means
  test_E$`p-value`
  #x's must be fairly close to the mean of this distribution
  #to get reasonable results. 
}
if(T) {
  # t distribution
  d_f <- 20
  f <- function(x) { dt(x, d_f)}
  l_f = -Inf
  u_f = Inf
  init_val <- c(-10, -5, 0.75, 1, 1.5, 3, 5, 7, 10)
  test_T <- test(B, f, init_val, l_f, u_f, rt, dt, df = d_f, leg = "Student t")
  test_T$Means
  test_T$`p-value`
  #The degrees of freedom must be larger than the absolute value 
  #of the maximum and minimum of the x's.
}
if(T){
  # Gumbel distribution
  mu <- 10
  b <- 5
  f <- function(x){ dgumbel(x, mu, b)}
  l_f <- -Inf
  u_f <- Inf
  init_val <- c(0, 7, 10, 11, 12, 15, 30)
  test_G <- test(B, f, init_val, l_f, u_f, rgumbel, dgumbel, location = mu, scale = b, leg = "Gumbel")
  test_G$Means
  test_G$`p-value`
}
if(T){
  # Weibull distribution
  a <- 5
  b <- 5
  f <- function(x){ dweibull(x, a, b)}
  l_f <- 0
  u_f <- Inf
  init_val <- c(1, 3.5, 4.2, 4.5, 4.8, 6, 10)
  test_W <- test(B, f, init_val, l_f, u_f, rweibull, dweibull, shape = a, scale = b, leg = "Weibull")
  test_W$Means
  test_W$`p-value`
  #x values must be centered around mean with a somewhat wide 
  #spread to get a somewhat accurate mean.
}
if(T){
  # Pareto distribution
  a <- 1
  b <- 3
  f <- function(x){ dpareto(x, a, b)}
  l_f <- 1.0001
  u_f <- Inf
  init_val <- c(1.1, 1.2, 1.3, 1.5, 1.9, 2.5)
  test_P <- test(B, f, init_val, l_f, u_f, rpareto, dpareto, location = a, shape = b, leg = "Pareto")
  test_P$Means
  test_P$`p-value`
}
if(T){
  # F distribution
  df1 <- 3
  df2 <- 5
  f <- function(x){ df(x, df1, df2)}
  l_f <- 0
  u_f <- 50
  init_val <- c(0.01, 0.2, 0.3, 0.5, 0.6, 5, 20, 30, 40)
  test_F <- test(B, f, init_val, l_f, u_f, rf, ddensity = df, df1 = df1, df2 = df2, leg = "F")
  test_F$Means
  test_F$`p-value`
}
if(T){
  # 1/(x^5)
  f <- function(x){ x^(-5)}
  l_f <- 0.01
  u_f <- Inf
  init_val <- c(1.5, 2, 3)
  test_poly <- ars(B, f,l_f, u_f, init_val)
  mean(test_poly)
  hist(test_poly, breaks = 75, main = "1/(x^5)")
}
if(T){
  # sin(x)
  a <- 100
  f <- function(x){ a*sin(x)}
  l_f <- pi/16
  u_f <- 15*pi/16
  init_val <- c(0.5, 0.9, 1.5, 2)
  test_sin <- ars(B, f, l_f, u_f, init_val)
  mean(test_sin)
  hist(test_sin, breaks = 10, main = "sin(x)", col = "grey95")
}
