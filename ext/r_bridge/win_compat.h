#ifndef WIN_COMPAT_H
#define WIN_COMPAT_H

#ifdef _WIN
#define EXPORT __declspec(dllexport)
#else
#define EXPORT // For other OS
#endif

#endif // WIN_COMPAT_H
