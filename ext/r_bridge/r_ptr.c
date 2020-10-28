#include <Rinternals.h>
#include <Rembedded.h>
#include <Rdefines.h>

#include "win_compat.h"

EXPORT void
r_ptr_unprotect( SEXP ptr )
{
    Rf_unprotect_ptr(ptr);
}

EXPORT void
r_ptr_gc( int num )
{
    UNPROTECT( num );
}

