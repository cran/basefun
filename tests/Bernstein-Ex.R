
library("basefun")

### check the approximation of a number of functions
f1 <- function(x) qnorm(pchisq(x, df = 3))
fun <- list(sin, cos, sqrt, log, f1)
dfun <- list(cos, function(x) -sin(x), function(x) -.5 * x^(-3/2), function(x) 1/x, 
             function(x) 1 / dnorm(qnorm(pchisq(x, df = 3))) * dchisq(x, df = 3))
### http://r.789695.n4.nabble.com/Derivative-of-the-probit-td2133341.html
ord <- 3:10
x <- seq(from = 0.01, to = 2*pi - 0.01, length.out = 100)
xvar <- numeric_var("x", support = range(x) + c(-.5, .5))
for (i in 1:length(fun)) {
    for (o in ord) {
        y <- fun[[i]](x)
        Bb <- Bernstein_basis(xvar, order = o)
        m <- lm(y ~ Bb(x) - 1, data = data.frame(y = y, x = x))
        R <- summary(m)$r.squared
        layout(matrix(1:2, ncol = 2))
        plot(x, fun[[i]](x), type = "l", col = "red", main = paste(deparse(fun[[i]]), o, R, sep = ":"))
        lines(x, fitted(m))
        plot(x, dfun[[i]](x), type = "l", col = "red", main = paste(deparse(fun[[i]]), o, R, sep = ":"))
        lines(x, predict(Bb, newdata = data.frame(x = x), deriv = c(x = 1), coef = coef(m)))
    }
}

### check linear extrapolation
order <- 50
xg <- seq(from = -1, to = 1, length.out = order + 1)
xvar2 <- numeric_var("x", support = c(-1.0, 1.0))
B <- Bernstein_basis(xvar2, order = order)
cf <- xg^2
x <- -150:150/100
X <- model.matrix(B, data = data.frame(x = x))
plot(x, x^2, type = "l", col = "red")
lines(x, X %*% cf)
###  f' is constant outside support
Xp <- model.matrix(B, data = data.frame(x = x), deriv = c(x = 1L))
plot(x, 2 * x, type = "l", col = "red")
lines(x, Xp %*% cf)
### also f' is linearily extrapolated if maxderiv > 1
Xp <- model.matrix(B, data = data.frame(x = x), deriv = c(x = 1L), maxderiv = 2L)
plot(x, 2 * x, type = "l", col = "red")
lines(x, Xp %*% cf)

### Legendre to Bernstein
## Example from doi: 10.1016/j.amc.2007.09.050
A <- basefun:::.L2B(4L)
B <- cbind(1, c(-1, -.5, 0, .5, 1), 
              c(1, -.5, -1, -.5, 1), 
              c(-1, 2, 0, -2, 1),  
              c(1, -4, 6, -4, 1))
stopifnot(max(abs(A - B)) < .Machine$double.eps)

### Bernstein to Legendre
stopifnot(max(abs(solve(A) - basefun:::.B2L(4L))) < sqrt(.Machine$double.eps))

### Bernstein(log(y))
x <- 1:100 / 10
y <- log(x)
xvar <- numeric_var("x", bounds = c(0.01, Inf), support = c(.1, 9))
xb <- Bernstein_basis(xvar, ui = "increasing", log_first = TRUE, order = 6)
X <- model.matrix(xb, data = data.frame(x = x))
Xprime <- model.matrix(xb, data = data.frame(x = x), deriv = c("x" = 1))
cf <- coef(lm(y ~ 0 + X))
stopifnot(max(abs(y - X %*% cf)) < .Machine$double.eps^(1/2))
stopifnot(max(abs(1 / x[-1] - Xprime[-1,] %*% cf)) < .Machine$double.eps^(1/2))

### log-linear function
xvar <- numeric_var("x", bounds = c(0.01, Inf), support = c(.1, 9))
xb <- Bernstein_basis(xvar, ui = "increasing", log_first = TRUE, order = 1)
X <- model.matrix(xb, data = data.frame(x = x))
Xprime <- model.matrix(xb, data = data.frame(x = x), deriv = c("x" = 1))
cf <- coef(lm(y ~ 0 + X))
stopifnot(max(abs(y - X %*% cf)) < .Machine$double.eps^(1/2))
stopifnot(max(abs(1 / x[-1] - Xprime[-1,] %*% cf)) < .Machine$double.eps^(1/2))

x <- 10:1000/ 1000 
y <- 1 + 2 * log(x)
lx <- log(x)
xv <- numeric_var("lx", support = log(c(.3, .7)), bounds = log(c(0.01, .99)))
b2 <- Bernstein_basis(xv, order = 6)
X2 <- model.matrix(b2, data = data.frame(lx = lx), deriv = c(lx = 0))
X2p <- model.matrix(b2, data = data.frame(lx = lx), deriv = c(lx = 1))
X2pp <- model.matrix(b2, data = data.frame(lx = lx), deriv = c(lx = 2))
m2 <- lm(y ~ 0 + X2)

xv <- numeric_var("x", support = c(.3, .7), bounds = c(.01, .99))
b3 <- Bernstein_basis(xv, order = 6, log_first = TRUE)
X3 <- model.matrix(b3, data = data.frame(x = x), deriv = c(x = 0))
X3p <- model.matrix(b3, data = data.frame(x = x), deriv = c(x = 1))
X3pp <- model.matrix(b3, data = data.frame(x = x), deriv = c(x = 2))
m3 <- lm(y ~ 0 + X3)

stopifnot(max(abs(X2 %*% coef(m2) - X3 %*% coef(m3))) < .Machine$double.eps^(1/2))
stopifnot(max(abs(X2p %*% coef(m2) / x - X3p %*% coef(m3))) <  .Machine$double.eps^(1/2))
stopifnot((X2pp - X2p) %*% coef(m2) / (x^2) - X3pp %*% coef(m3) < .Machine$double.eps^(1/2))

try(model.matrix(b3, data = data.frame(x = x), deriv = c(x = 3)))

xv <- numeric_var("lx", support = log(c(.3, .7)), bounds = log(c(0.01, .99)))
b2 <- Bernstein_basis(xv, order = 6, extrapolate = TRUE)
X2 <- model.matrix(b2, data = data.frame(lx = lx), deriv = c(lx = 0))
X2p <- model.matrix(b2, data = data.frame(lx = lx), deriv = c(lx = 1))
X2pp <- model.matrix(b2, data = data.frame(lx = lx), deriv = c(lx = 2))
m2 <- lm(y ~ 0 + X2)

xv <- numeric_var("x", support = c(.3, .7), bounds = c(.01, .99))
b3 <- Bernstein_basis(xv, order = 6, log_first = TRUE, extrapolate = TRUE)
X3 <- model.matrix(b3, data = data.frame(x = x), deriv = c(x = 0))
X3p <- model.matrix(b3, data = data.frame(x = x), deriv = c(x = 1))
X3pp <- model.matrix(b3, data = data.frame(x = x), deriv = c(x = 2))
m3 <- lm(y ~ 0 + X3)

stopifnot(max(abs(X2 %*% coef(m2) - X3 %*% coef(m3))) < .Machine$double.eps^(1/2))
stopifnot(max(abs(X2p %*% coef(m2) / x - X3p %*% coef(m3))) <  .Machine$double.eps^(1/2))
stopifnot((X2pp - X2p) %*% coef(m2) / (x^2) - X3pp %*% coef(m3) < .Machine$double.eps^(1/2))

try(model.matrix(b3, data = data.frame(x = x), deriv = c(x = 3)))

