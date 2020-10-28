#include <Rinternals.h>
#include <Rembedded.h>
#include <Rdefines.h>

#include "win_compat.h"

EXPORT void
r_embedded_init()
{
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
}

