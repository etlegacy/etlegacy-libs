if(WIN32)
        # FIXME: incomplete windows build with bundled libs

        #-----------------------------------------------------------------
        # Build bundled JPEG library
        #-----------------------------------------------------------------
        add_custom_command(OUTPUT ${CMAKE_SOURCE_DIR}/libs/jpeg/libjpeg.lib
                        COMMAND NMAKE /f makefile.vc setup-v10 && NMAKE /f makefile.vc
                        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/libs/jpeg
        )

        add_custom_target(bundled_jpeg
                        DEPENDS ${CMAKE_SOURCE_DIR}/libs/jpeg/libjpeg.lib
        )

        #-----------------------------------------------------------------
        # Build bundled cURL library
        #-----------------------------------------------------------------
        add_custom_command(OUTPUT ${CMAKE_SOURCE_DIR}/libs/curl/builds/libcurl-release-static-ipv6/lib/libcurl_a.lib
                        COMMAND NMAKE /f Makefile.vc mode=static USE_SSPI=no USE_IDN=no
                        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/libs/curl/winbuild
        )

        add_custom_target(bundled_curl
                        DEPENDS ${CMAKE_SOURCE_DIR}/libs/curl/builds/libcurl-release-static-ipv6/lib/libcurl_a.lib
        )

        # return compiled libs to the parent CMakeLists.txt
        set(BUNDLED_LIBRARIES "${CMAKE_SOURCE_DIR}/libs/curl/builds/libcurl-release-static-ipv6/lib/libcurl_a.lib"
                        "${CMAKE_SOURCE_DIR}/libs/jpeg/libjpeg.lib"
                        "${CMAKE_SOURCE_DIR}/libs/sdl-windows/lib/x86/SDL.lib"
                        "${CMAKE_SOURCE_DIR}/libs/sdl-windows/lib/x86/SDLmain.lib"
                        PARENT_SCOPE)
elseif(UNIX)
        if(CROSS_COMPILE32)
                set(CROSS_COMPILE32_FLAGS CFLAGS=-m32 LDFLAGS=-m32)
        else(CROSS_COMPILE32)
                set(CROSS_COMPILE32_FLAGS "")
        endif(CROSS_COMPILE32)

        #-----------------------------------------------------------------
        # Build bundled cURL library
        #-----------------------------------------------------------------
        add_custom_command(OUTPUT ${CMAKE_SOURCE_DIR}/libs/curl/lib/.libs/libcurl.a 
                        COMMAND ${CROSS_COMPILE32_FLAGS} ./configure --enable-shared=no --enable-static=yes --without-libssh2 --enable-http --enable-ftp --disable-gopher --enable-file --disable-ldap --disable-dict --disable-telnet --disable-manual --enable-libgcc --disable-ipv6 --disable-ares --without-ssl --without-zlib --without-libidn && make
                        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/libs/curl
                        )

        add_custom_target(bundled_curl
                        DEPENDS ${CMAKE_SOURCE_DIR}/libs/curl/lib/.libs/libcurl.a 
        )
        
        #-----------------------------------------------------------------
        # Build bundled JPEG library
        #-----------------------------------------------------------------
        add_custom_command(OUTPUT ${CMAKE_SOURCE_DIR}/libs/jpeg/.libs/libjpeg.a 
                        COMMAND ${CROSS_COMPILE32_FLAGS} ./configure && make
                        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/libs/jpeg
        )

        add_custom_target(bundled_jpeg
                        DEPENDS ${CMAKE_SOURCE_DIR}/libs/jpeg/.libs/libjpeg.a
        )

        #-----------------------------------------------------------------
        # Build bundled SDL library
        #-----------------------------------------------------------------
        add_custom_command(OUTPUT ${CMAKE_SOURCE_DIR}/libs/sdl/build/.libs/libSDL.a
                        COMMAND ${CROSS_COMPILE32_FLAGS} ./configure && make
                        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/libs/sdl
        )

        add_custom_target(bundled_sdl
                        DEPENDS ${CMAKE_SOURCE_DIR}/libs/sdl/build/.libs/libSDL.a
        )
        
        # return compiled libs to the parent CMakeLists.txt
        set(BUNDLED_LIBRARIES "${CMAKE_SOURCE_DIR}/libs/curl/lib/.libs/libcurl.a"
                        "${CMAKE_SOURCE_DIR}/libs/jpeg/.libs/libjpeg.a"
                        "${CMAKE_SOURCE_DIR}/libs/sdl/build/.libs/libSDL.a"
                        PARENT_SCOPE)
endif()

# return include dirs to the parent CMakeLists.txt
set(BUNDLED_INCLUDE_DIRS "${CMAKE_SOURCE_DIR}/libs/curl/include"
	"${CMAKE_SOURCE_DIR}/libs/jpeg"
	"${CMAKE_SOURCE_DIR}/libs/sdl/include"
	PARENT_SCOPE)