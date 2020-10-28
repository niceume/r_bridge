#include <Rinternals.h>
#include <Rembedded.h>
#include <Rdefines.h>
#include <R_ext/Parse.h>


SEXP
mysum (SEXP vec)
{
int int_sum = 0;
double dbl_sum = 0.0;
R_xlen_t size = xlength(vec);
unsigned int idx ;
SEXP result;

switch(TYPEOF(vec)){
    case INTSXP:
        for( idx = 0; idx < size; ++idx ){
            int_sum = int_sum + INTEGER(vec)[idx] ; 
        }
        Rf_protect(result = Rf_ScalarInteger( int_sum ) );
        break;
    case REALSXP:
        for( idx = 0; idx < size; ++idx ){
            dbl_sum = dbl_sum + REAL(vec)[idx] ; 
        }
        Rf_protect(result = Rf_ScalarReal( dbl_sum ) );
        break;
    default:
        Rf_protect(result = Rf_ScalarLogical(NA_LOGICAL) );
    }
    
    Rf_unprotect_ptr(result);
    return result;
}

void
r_mysum(SEXP input)
{
    SEXP result;
    Rf_protect( result = mysum( input ));
    SEXP ptrRetVal;
    int nErr;
    Rf_protect(ptrRetVal = R_tryEval( LCONS( Rf_install( "print" ), LCONS( result , R_NilValue )) , R_GlobalEnv, &nErr));

    Rf_unprotect_ptr(ptrRetVal);
    Rf_unprotect_ptr(result);
}

/*
To write the above code in Ruby, the following methods are required



1. RBridge::init()
2. RBridge::new_integer_vec()
   RBridge::new_real_vec()
   RBridge::new_logical_vec()
   RBridge::new_string_vec()

   RBrideg::new_list()

3. RBridge::new_function()
   RBridge::new_symbol()
   RBridge::new_arguments()

   RBridge::lcons()

3. RBridge::convert_to_r_objects()
4. RBridge::eval()
5. RBridge::close()
RBridge::

As structure

class RBridge::Sexp
  def initalize( type , name , tag , r_sexp)

  end

end

class RBridge::LangCons
  def initialize( car, cdr )
  end

end

*/
