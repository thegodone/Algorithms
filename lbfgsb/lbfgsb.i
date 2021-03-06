/*
 * lbfgsb.i -
 *
 * Yorick wrapper for L-BFGS-B optimizer.
 *
 *-----------------------------------------------------------------------------
 *
 * This software is licensed under the MIT "Expat" License.
 *
 * Copyright (C) 2002-2005, 2015: Éric Thiébaut <eric.thiebaut@univ-lyon1.fr>
 *
 *-----------------------------------------------------------------------------
 */

if (is_func(plug_in)) plug_in, "ylbgsb";

extern __lbfgsb__;
/* PROTOTYPE
     int lbfgsb(int n, int m, double array x, double array f,
                double array g, double array l, double array u,
                int array bnd, double factr, double pgtol,
                char array task, char array csave, int array isave,
                double array dsave, int iprint); */

func lbfgsb_setup(m, &x, inf=, sup=, bnd=, factr=, pgtol=)
/* DOCUMENT ws = lbfgsb_setup(m, x);

     Create a workspace for minimize a multi-variate function with simple bound
     constraints.  M is the maximum number of variable metric corrections used
     to define the limited memory approximation of the Hessian matrix.  X is the
     starting value of the variables.

     If the starting variables are not feasible, they will be projected on the
     feasible set.

   KEYWORDS:
     The following keywords are available:

     INF = The lower bounds on X.  INF must be a scalar or an array with as
           many elements as X.

     SUP = The upper bounds on X.  SUP must be a scalar or an array with as
           many elements as X.

     BND = The type of bounds imposed on the variables.  BND must be a scalar
           or an array with as many elements as X and must be specified as
           follows:
               BND(i) = 0 if X(i) is unbounded,
                        1 if X(i) has only a lower bound,
                        2 if X(i) has both lower and upper bounds, and
                        3 if X(i) has only an upper bound.
           If BND is not specified, it is computed according to SUP and INF.

     FACTR = The stopping criterion based on the convergence of the penalty
           function F.  The iteration will stop when:

               (F_k - F_{k+1})/max{|F_k|,|F^_k+1}|,1} <= FACTR*EPSMCH

           where EPSMCH is the machine precision, which is automatically
           generated by the code.  Typical values for FACTR: 1e+12 for low
           accuracy; 1e+7 for moderate accuracy; 1e+1 for extremely high
           accuracy.  The default is FACTR=1e7.

     PGTOL = The stopping criterion based on the projected gradient.  The
           iteration will stop when

                  max{|PG(i)|; i = 1, ..., n} <= PGTOL

           where PG(i) is the i-th component of the projected gradient.
           The default is PGTOL=1e-10.


   EXAMPLE:
     For maximum flexibility, this implementation of L-BFGS-B uses reverse
     communication.  Typical usage is:

         x = ...; // initial variables
         ws = lbfgsb_setup(7, x); // create workspace
         job = LBFGSB_FG; // first task is to compute function and gradient
         for (;;) {
           if (job ==  LBFGSB_FG) {
             fx = f(x);  // compute penalty function at x
             gx = g(x);  // compute gradient of penalty function at x
           } else if (job == LBFGSB_CONVERGENCE) {
             // algorithm has converged
             break;
           } else if (job == LBFGSB_NEW_X) {
             // a new iterate is available for inspection
             write, fx;
           } else if (job == LBFGSB_WARNING) {
             write, format="WARNING: %s\n", lbfgsb_message(ws);
             break;
           } else if (job == LBFGSB_ERROR) {
             write, format="ERROR: %s\n", lbfgsb_message(ws);
             break;
           } else {
             error, "unexpected task";
           }
           // perform one iteration of the algorithm
           job = lbfgsb_iterate(ws, x, fx, gx);
         }


   SEE ALSO: lbfgsb_iterate, lbfgsb_message.
 */
{
  n = numberof(x);
  if (structof(x) != double) error, "X must be a double array";

  if (is_void(bnd)) {
    if (is_void(inf)) {
      bnd = (is_void(sup) ? 0n : 3n);
    } else {
      bnd = (is_void(sup) ? 1n : 2n);
    }
    bnd = array(bnd, dimsof(x));
  } else if (is_integer(bnd)) {
    if (! is_scalar(bnd) && numberof(bnd) != n) {
      error, "bad number of elements for BND";
    }
    bnd = int(bnd); /* make a private copy/conversion */
    if (min(bnd) < 0n || max(bnd) > 3n) error, "bad value in BND";
    if (is_void(inf) && (anyof(bnd == 1n) || anyof(bnd == 2n))) {
      error, "no lower bound specified with BND = 1 or 2";
    }
    if (is_void(sup) && (anyof(bnd == 2n) || anyof(bnd == 3n))) {
      error, "no upper bound specified with BND = 1 or 2";
    }
    if (is_scalar(bnd)) {
      bnd = array(bnd, dimsof(x));
    }
  } else {
    error, "BND must be an array of integers";
  }

  if (is_integer(inf) || is_real(inf)) {
    /* make a private copy / convert to double */
    if (is_scalar(inf)) {
      inf = array(double(inf), dimsof(x));
    } else if (numberof(inf) == n) {
      inf = double(inf);
    } else {
      error, "bad number of elements for INF";
    }
  } else if (is_void(inf)) {
    inf = array(double, dimsof(x));
  } else {
    error, "bad data type for INF";
  }

  if (is_integer(sup) || is_real(sup)) {
    /* make a private copy / convert to double */
    if (is_scalar(sup)) {
      sup = array(double(sup), dimsof(x));
    } else if (numberof(sup) == n) {
      sup = double(sup);
    } else {
      error, "bad number of elements for SUP";
    }
  } else if (is_void(sup)) {
    sup = array(double, dimsof(x));
  } else {
    error, "bad data type for SUP";
  }

  if (is_void(pgtol)) pgtol = 1e-10;
  if (is_void(factr)) factr = 1e7;

  ctask = csave = array(char, 61);
  ctask(1) = 'S';
  ctask(2) = 'T';
  ctask(3) = 'A';
  ctask(4) = 'R';
  ctask(5) = 'T';
  dsave = array(double, 29 + 2*m*n + 5*n + 11*m*m + 8*m);
  isave = array(int, 48 + 3*n);
  ws = save(m, n, factr, pgtol, inf, sup, bnd, ctask, csave, isave, dsave);
  job = lbfgsb_iterate(ws, x, 0.0, x);
  if (job != LBFGSB_FG) error, lbfgsb_message(ws);
  return ws;
}

func lbfgsb_message(ws, csave) { return strchar((csave ? ws.csave : ws.ctask)); }
/* DOCUMENT lbfgsb_message(ws, 0/1);
     Return message stored into LBFGSB workspace WS.  If second argument is
     true, returns the contents of CSAVE; otherwise, returns the value of
     TASK.

   SEE ALSO: lbfgsb_setup.
 */

local LBFGSB_START, LBFGSB_FG, LBFGSB_NEW_X, LBFGSB_CONVERGENCE;
local LBFGSB_WARNING, LBFGSB_ERROR;
func lbfgsb_iterate(ws, &x, &f, &g)
/* DOCUMENT job = lbfgsb_iterate(ws, x, f, g);

     Perform next LBFGSB step.  Argument WS is the workspace as returned by
     lbfgsb_setup (which see), X is for the current parameters, F and G are the
     function value and the gradient at X.  The returned value is one of:

       1   - X was set to a new try value: caller must compute F and G
             accordingly and call lbfgsb_iterate again.
       2   - Successful iteration: current X contains an improved solution
             available for examination (F and G contains the corresponding
             function value and gradient).  If the caller want to continue
             with optimization, it just have to call lbfgsb_iterate again (no
             need to recompute F and G).
       3   - Convergence: the final solution and corresponding function
             value and gradient are in X, F and G.
       4   - Warning: the algorithm can not improve the solution.  Best
             solution found so far is available in X, F and G.  Use
             lbfgsb_message to get the error message.
       5   - Error: some error detected.  Use lbfgsb_message to get the
             error message.

   SEE ALSO: lbfgsb_setup, lbfgsb_message.
 */
{
  m = ws.m;
  n = ws.n;
  if (numberof(x) != n || structof(x) != double) {
    error, swrite(format="X must be a double array with %d elements", n);
  }
  if (! is_scalar(f) || ! (is_real(f) || is_integer(f))) {
    error, "F must be a real scalar";
  }
  if (numberof(g) != n || structof(g) != double) {
    error, swrite(format="G must be a double array with %d elements", n);
  }
  return __lbfgsb__(n, m, x, f, g, ws.inf, ws.sup, ws.bnd, ws.factr, ws.pgtol,
                    ws.ctask, ws.csave, ws.isave, ws.dsave, -1);
}
LBFGSB_START       = 0n;
LBFGSB_FG          = 1n;
LBFGSB_NEW_X       = 2n;
LBFGSB_CONVERGENCE = 3n;
LBFGSB_WARNING     = 4n;
LBFGSB_ERROR       = 5n;

func lbfgsb_solve(fg, x, inf=, sup=, bnd=, mem=,
                  factr=, pgtol=, maxeval=, maxiter=,
                  verb=, output=, printer=, save_best=)
/* DOCUMENT x = lbfgsb_solve(fg, x0);

     Solve an optimization problem with L-BFGS-B algorithm.  FG is a Yorick
     function which computes the penalty to minimize and its gradient.  X0
     gives the initial variables to start with.

     The function FG must be defined as:

         func fg(x, &gx) {
            fx = f(x);  // compute penalty function at x
            gx = g(x);  // compute gradient of penalty function at x
            return fx;  // return penalty
         }

     Of course FG can also be any Yorick object callable as a function
     (e.g., a closure) and behaving like the function above.

     The initial variables X0 are needed to figure out the size of the
     problem and allocate ressources.  If they are not feasible, they will
     be projected into the feasble set.

     Keywords INF, SUP and BND can be used to specify the inferior bounds,
     the superior bounds on the variables and the types of the bounds.  See
     lbfgsb_setup for more details.

     Keyword MEM set the maximum number of variable metric corrections used
     to define the limited memory approximation of the Hessian matrix.  The
     default is to use at most 5 corrections.

     Keywords FACTR and PGTOL can be used to specify the convergence
     criterion.  See lbfgsb_setup for more details.

     Keywords MAXEVAL and MAXITER can be used to sepcify the maximum number
     of function evaluations and the maximum number of iterations.
     Negative values are the same as setting no limits which is the
     default.  Unless keyword SAVE_BEST is set true, the actual maximum
     number of function valuations may be slightly lager than MAXEVAL
     because the function only returns after a finite number of iterations
     (and there may be more than one evaluations per iteration).

     Keyword VERB specify the level of verbosity.  It can be set with an
     integer number to specify that every VERB iterations some informations
     about the current iteration should be printed.  If VERB is non-zero,
     informations about the very first and very last iteration are always
     printed (even if not a multiple of VERB).  By default, nothing is
     printed (except error or warning messages).  Keyword OUTPUT can be set
     with a text stream or a file name to which print the iterations
     information.

     Keyword PRINTER can be set with a function (or an object calable as a
     function) to be called after every iteration as:

         printer, ws, x, fx, gx, iter, eval, t;

     where WS is the L-BFGS-B workspace, X are the current variables, FX
     the corresponding function value, GX the corresponding gradient, ITER
     the number of iterations, EVAL the number of function evaluations and
     T the elasped time in seconds (as an array of 3 values as returned by
     the timer function).

     Keyword SAVE_BEST can be set true to save the best solution so far in
     external variables: `lbfgsb_best_x` for the solution, `lbfgsb_best_fx`
     for the corresponding function value and `lbfgsb_best_gx` for the
     corresponding gradient.  Typical usage is:

         local lbfgsb_best_x, lbfgsb_best_fx, lbfgsb_best_gx;
         x = lbfgsb_solve(fg, x, ...);
         fx = lbfgsb_best_fx;

     If keyword SAVE_BEST is set true, the returned value is always the
     best solution found so far and, if keyword MAXEVAL is set with a
     nonnegative value, at most MAXEVAL+1 function evaluations will be
     performed.


   SEE ALSO: lbfgsb_setup, timer, closure.
 */
{
  /* Extern variables to save best solution so far. */
  extern lbfgsb_best_x, lbfgsb_best_fx, lbfgsb_best_gx;

  /* Default options. */
  if (is_void(mem)) mem = 5;
  if (is_void(maxiter)) maxiter = -1;
  if (is_void(maxeval)) maxeval = -1;

  /* Create optimization workspace. */
  ws = lbfgsb_setup(mem, x, inf=inf, sup=sup, bnd=bnd, factr=factr, pgtol=pgtol);
  job = LBFGSB_FG;

  /* Some constants. */
  true = 1n;
  false = 0n;

  /* Optimization loop. */
  eval = 0;
  iter = 0;
  t = array(double, 3);
  timer, t;
  t0 = t;
  finish = false;
  msg = string(0);
  for (;;) {
    local fx, gx;

    if (job == LBFGSB_FG) {
      /* Compute function and gradient. */
      fx = fg(x, gx);
      ++eval;
      if (save_best && (eval == 1 || fx < lbfgsb_best_fx)) {
        /* Save best solution so far. */
        lbfgsb_best_x = x;
        lbfgsb_best_fx = fx;
        lbfgsb_best_gx = gx;
      }
      if (save_best && maxeval >= 0 && eval > maxeval) {
        msg = swrite(format="WARNING: too many function evaluations (%d)",
                     eval);
        finish = true;
      }
    } else if (job == LBFGSB_NEW_X || job == LBFGSB_CONVERGENCE) {
      ++iter;
      finish = (job == LBFGSB_CONVERGENCE);
      if (! finish && maxiter >= 0 && iter >= maxiter) {
        msg = swrite(format="WARNING: too many iterations (%d)", iter);
        finish = true;
      }
      if (! finish && maxeval >= 0 && eval >= maxeval) {
        msg = swrite(format="WARNING: too many function evaluations (%d)",
                     eval);
        finish = true;
      }
    } else if (job == LBFGSB_WARNING) {
      msg = ("WARNING: " + lbfgsb_message(ws));
      finish = true;
    } else if (job == LBFGSB_ERROR) {
      msg = ("ERROR: " + lbfgsb_message(ws));
      break;
    } else {
      error, "unexpected job";
    }

    if (finish || job == LBFGSB_NEW_X || eval == 1) {
      timer, t;
      if (! is_void(printer)) {
        printer, ws, x, fx, gx, iter, eval, t - t0;
      }
      if (verb && (finish || (iter%verb) == 0)) {
        if (eval == 1) {
          if (is_void(output)) {
            prefix = " ";
          } else {
            if (structof(output) == string) {
              output = open(output, "a");
            } else if (typeof(output) != "text_stream") {
              error, "bad value for keyword OUTPUT";
            }
            prefix = "#";
          }
          write, output, format="%s%s\n%s%s\n", prefix,
            " ITER     EVAL   TIME (s)            PENALTY           GRADIENT",
            prefix,
            "-----------------------------------------------------------------";
        }
        write, output, format=" %6d  %6d  %9.3f  %24.16e  %12.6e\n",
          iter, eval, (t(3) - t0(3)), fx, sqrt(avg(gx*gx));
      }
      if (finish) {
        if (msg) write, format="%s\n", msg;
        break;
      }
    }

    /* Call optimizer. */
    job = lbfgsb_iterate(ws, x, fx, gx);
  }
  return (save_best ? lbfgsb_best_x : x);
}

/*---------------------------------------------------------------------------*/
