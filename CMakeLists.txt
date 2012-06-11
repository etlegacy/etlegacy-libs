if(WIN32)
        message(FATAL_ERROR "Sorry, building bundled libs is not yet supported on Windows.")
elseif(UNIX)
        #-----------------------------------------------------------------
        # Build bundled cURL library
        #-----------------------------------------------------------------
        add_custom_command(OUTPUT ${CMAKE_SOURCE_DIR}/libs/curl/lib/.libs/libcurl.a 
                        COMMAND CFLAGS=-m32 LDFLAGS=-m32 ./configure --enable-shared=no --enable-static=yes --without-libssh2 --enable-http --enable-ftp --disable-gopher --enable-file --disable-ldap --disable-dict --disable-telnet --disable-manual --enable-libgcc --disable-ipv6 --disable-ares --without-ssl --without-zlib --without-libidn && make
                        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/libs/curl
                        )

        add_custom_target(bundled_curl
                        DEPENDS ${CMAKE_SOURCE_DIR}/libs/curl/lib/.libs/libcurl.a 
        )
        
        #-----------------------------------------------------------------
        # Build bundled JPEG library
        #-----------------------------------------------------------------
        add_custom_command(OUTPUT ${CMAKE_SOURCE_DIR}/libs/jpeg/.libs/libjpeg.a 
                        COMMAND CFLAGS=-m32 LDFLAGS=-m32 ./configure && make
                        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/libs/jpeg
        )

        add_custom_target(bundled_jpeg
                        DEPENDS ${CMAKE_SOURCE_DIR}/libs/jpeg/.libs/libjpeg.a
        )

        #-----------------------------------------------------------------
        # Build bundled SDL library
        #-----------------------------------------------------------------
        add_custom_command(OUTPUT ${CMAKE_SOURCE_DIR}/libs/sdl/build/.libs/libSDL.a
                        COMMAND CFLAGS=-m32 LDFLAGS=-m32 ./configure && make
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
        
        # return include dirs to the parent CMakeLists.txt
        set(BUNDLED_INCLUDE_DIRS "${CMAKE_SOURCE_DIR}/libs/curl/include"
                        "${CMAKE_SOURCE_DIR}/libs/jpeg"
                        "${CMAKE_SOURCE_DIR}/libs/sdl/include"
                        PARENT_SCOPE)
endif()
