#include <Rinternals.h>
#include <Rembedded.h>
#include <Rdefines.h>

#include <stdbool.h>

#include <stdint.h>
#define CSTACK_DEFNS

#include "win_compat.h"
#ifndef _WIN
#include <Rinterface.h>
#endif

#ifdef __FreeBSD__
#include <ieeefp.h>
fp_rnd_t fpmask_preset;
#endif

EXPORT void
r_embedded_init( bool unlimited_stack_size )
{

    #ifdef __FreeBSD__
        fpmask_preset = fpsetmask(0);
    #endif

    size_t localArgc = 3;
    char localArgs[][50] = {"R", "--silent", "--vanilla"};

    char *args[ localArgc ];
    for (size_t i = 0; i < localArgc; ++i){
        args[i] = localArgs[i];
    }

    // Rf_initEmbeddedR raises C stack usage limit error on multithreading environment.
    // Rf_initEmbeddedR( localArgc , args ); is replaced with the following code.

    if( unlimited_stack_size == false ){  // default stack size
      Rf_initialize_R( localArgc , args );
      setup_Rmainloop();
    }else{
      Rf_initialize_R( localArgc , args );
      #ifndef _WIN
      R_CStackLimit = (uintptr_t) -1 ;  // Set -1 for unlimited C stack size.
      #endif
      setup_Rmainloop();
    }
}

EXPORT void
r_embedded_end()
{
    Rf_endEmbeddedR(0);

    #ifdef __FreeBSD__
        fpsetmask(fpmask_preset);
    #endif
}

