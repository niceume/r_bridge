#include <Rinternals.h>
#include <Rembedded.h>
#include <Rdefines.h>

#include "win_compat.h"

EXPORT SEXP
r_lang_create_fcall( const char* fname, SEXP args)
{
    SEXP func;
    PROTECT( func = LCONS( Rf_install(fname), args ));
    return func;
}


EXPORT SEXP
r_lang_cons( SEXP car, SEXP cdr)
{
    SEXP cons_cell;
    PROTECT( cons_cell = LCONS( car, cdr ));
    return cons_cell;
}

EXPORT SEXP
r_lang_cons_gen( SEXP car )
{
    SEXP cons_cell;
    PROTECT( cons_cell = LCONS( car, R_NilValue ));
    return cons_cell;
}

EXPORT void
r_lang_set_tag( SEXP sexp, const char* tag_name )
{
    SET_TAG( sexp, Rf_install(tag_name));
}

EXPORT SEXP
r_lang_symbol( const char* symbol_name)
{
    SEXP r_symbol ;
    r_symbol = Rf_install(symbol_name);
    return r_symbol;
}

EXPORT SEXP
r_lang_nil()
{
    return R_NilValue;
}

EXPORT int
r_is_nil( SEXP obj)
{
    if( obj == R_NilValue ){
        return 1;
    }else{
        return 0;
    }
}


