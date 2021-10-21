#include <Rinternals.h>
#include <Rembedded.h>
#include <Rdefines.h>

#include "win_compat.h"

#ifdef __FreeBSD__
#include <ieeefp.h>
fp_rnd_t fpmask_preset;
#endif

EXPORT void
r_embedded_init()
{

    #ifdef __FreeBSD__
        fpmask_preset = fpsetmask(0);
    #endif

    size_t localArgc = 2;
    char localArgs[][50] = {"R", "--silent"};

    char *args[ localArgc ];
    for (size_t i = 0; i < localArgc; ++i){
        args[i] = localArgs[i];
    }

    Rf_initEmbeddedR( localArgc , args );
}

EXPORT void
r_embedded_end()
{
    Rf_endEmbeddedR(0);

    #ifdef __FreeBSD__
        fpsetmask(fpmask_preset);
    #endif
}

