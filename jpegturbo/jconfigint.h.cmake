/* libjpeg-turbo build number */
#define BUILD  "0"

/* Compiler's inline keyword */
#undef inline

/* How to obtain function inlining. */
#define INLINE  __inline

/* Define to the full name of this package. */
#define PACKAGE_NAME  "libjpeg-turbo"

/* Version number of package */
#define VERSION  "2.0.4"

/* The size of `size_t', as computed by sizeof. */
#cmakedefine SIZEOF_SIZE_T  @SIZEOF_SIZE_T@

/* Define if your compiler has __builtin_ctzl() and sizeof(unsigned long) == sizeof(size_t). */
#cmakedefine HAVE_BUILTIN_CTZL

/* Define to 1 if you have the <intrin.h> header file. */
#cmakedefine HAVE_INTRIN_H

#if defined(_MSC_VER) && defined(HAVE_INTRIN_H)
#if (SIZEOF_SIZE_T == 8)
#define HAVE_BITSCANFORWARD64
#elif (SIZEOF_SIZE_T == 4)
#define HAVE_BITSCANFORWARD
#endif
#endif
