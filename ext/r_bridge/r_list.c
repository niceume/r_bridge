#include <Rinternals.h>
#include <Rembedded.h>
#include <Rdefines.h>

#include "win_compat.h"

EXPORT SEXP
r_list_create( SEXP name_vec, int size )
{
    SEXP lst;
    PROTECT( lst = allocVector(VECSXP, size));
    setAttrib( lst, R_NamesSymbol, name_vec);
    return lst;
}

EXPORT void
r_list_set_elem( SEXP lst, int idx, SEXP elem_vec )
{
    SET_VECTOR_ELT( lst, idx, elem_vec );
}

EXPORT SEXP
r_list_to_dataframe( SEXP lst )
{
    setAttrib( lst , R_ClassSymbol, ScalarString(mkChar("data.frame")));
    return lst;
}

EXPORT void
r_dataframe_set_rownames( SEXP lst, SEXP rownames )
{
    setAttrib(lst, R_RowNamesSymbol, rownames);
}

