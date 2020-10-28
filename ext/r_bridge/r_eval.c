#include <Rinternals.h>
#include <Rembedded.h>
#include <Rdefines.h>

#include "win_compat.h"

EXPORT SEXP
r_eval( SEXP sexp )
{
    SEXP ptrRetVal;
    int nErr  = 0;
    PROTECT(ptrRetVal = R_tryEval( sexp, R_GlobalEnv, &nErr));
    if( nErr ){
          Rprintf("R's eval error deteccted: %d\n", nErr);
          Rf_unprotect_ptr(ptrRetVal);
          return R_NilValue;
    }
    return ptrRetVal;
}

EXPORT void
r_eval_no_return( SEXP sexp )
{
    SEXP ptrRetVal;
    int nErr = 0;
    Rf_protect(ptrRetVal = R_tryEval( sexp, R_GlobalEnv, &nErr));
    Rf_unprotect_ptr(ptrRetVal);
}

