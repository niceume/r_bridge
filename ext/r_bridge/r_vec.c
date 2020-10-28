#include <Rinternals.h>
#include <Rembedded.h>
#include <Rdefines.h>

#include "win_compat.h"

EXPORT SEXP
r_vec_create_str( int size )
{
    SEXP vec;
    PROTECT( vec = allocVector(STRSXP, size));
    return vec;
}

EXPORT SEXP
r_vec_create_int( int size )
{
    SEXP vec;
    PROTECT(vec = Rf_allocVector(INTSXP, size));
    return vec;
}

EXPORT SEXP
r_vec_create_real( int size )
{
    SEXP vec;
    PROTECT(vec = Rf_allocVector(REALSXP, size));
    return vec;
}


EXPORT SEXP
r_vec_create_lgl( int size )
{
    SEXP vec;
    PROTECT(vec = Rf_allocVector(LGLSXP, size));
    return vec;
}

EXPORT void
r_vec_set_str( SEXP vec, char** ary , int size)
{
    int idx;
    for(idx=0; idx<size; ++idx){
        SET_STRING_ELT(vec, idx, mkChar( ary[idx] ));
    }
}

EXPORT void
r_vec_set_int( SEXP vec, int* ary , int size)
{
    int idx;
    for(idx=0; idx<size; ++idx){
      INTEGER(vec)[idx] = ary[idx];
    }
}

EXPORT void
r_vec_set_real( SEXP vec, double* ary , int size)
{
    int idx;
    for(idx=0; idx<size; ++idx){
      REAL(vec)[idx] = ary[idx];
    }
}

EXPORT void
r_vec_set_lgl( SEXP vec, int* ary , int size)
{
    int idx;
    for(idx=0; idx<size; ++idx){
      LOGICAL(vec)[idx] = ary[idx];
    }
}


