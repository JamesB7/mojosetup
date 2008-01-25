/**
 * MojoSetup; a portable, flexible installation application.
 *
 * Please see the file LICENSE.txt in the source's root directory.
 *
 *  This file written by Ryan C. Gordon.
 */

// You also need to compile unix.c, but this lets us add some things that
//  cause conflicts between the Be headers and MojoSetup, and use C++. These
//  are largely POSIX things that are missing from BeOS 5...keeping them here
//  even on Zeta lets us be binary compatible across everything, I think.

#if PLATFORM_BEOS

#include <stdio.h>
#include <be/kernel/image.h>
#include <be/kernel/OS.h>

void *beos_dlopen(const char *fname, int unused)
{
    const image_id lib = load_add_on(fname);
    (void) unused;
    if (lib < 0)
        return NULL;
    return (void *) lib;
} // beos_dlopen


void *beos_dlsym(void *lib, const char *sym)
{
    void *addr = NULL;
    if (get_image_symbol((image_id) lib, sym, B_SYMBOL_TYPE_TEXT, &addr))
        return NULL;
    return addr;
} // beos_dlsym


void beos_dlclose(void *lib)
{
    unload_add_on((image_id) lib);
} // beos_dlclose


void beos_usleep(unsigned long microseconds)
{
    snooze(microseconds);
} // beos_usleep

#endif  // PLATFORM_BEOS

// end of beos.c ...
