#pragma once

#if defined(_WIN32) || defined(__CYGWIN__)
    #ifdef EUINEO_EXPORTS
        #define EUINEO_API __declspec(dllexport)
    #else
        #define EUINEO_API __declspec(dllimport)
    #endif
#else
    #if __GNUC__ >= 4
        #define EUINEO_API __attribute__ ((visibility ("default")))
    #else
        #define EUINEO_API
    #endif
#endif
