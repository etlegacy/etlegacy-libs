if(WIN32)
	include(ExternalProject)
	include(CheckIncludeFile)
	#-----------------------------------------------------------------
	# Build bundled JPEG library
	#-----------------------------------------------------------------
	if(BUNDLED_JPEG) # static
		check_include_file ( stddef.h HAVE_STDDEF_H )
		check_include_file ( stdlib.h HAVE_STDLIB_H )
		
		set(JPEG_LIB "${CMAKE_SOURCE_DIR}/libs/jpeg")
		if(MSVC)
    		add_definitions ( -D_CRT_SECURE_NO_WARNINGS )
  		endif()

		if(WIN32 AND NOT CYGWIN)
		  set(TWO_FILE_COMMANDLINE true)
		endif()
		#configure_file (${JPEG_LIB}/jconfig.h.cmake ${JPEG_LIB}/jconfig.h)
		configure_file (${JPEG_LIB}/jconfig.h.cmake ${JPEG_LIB}/jconfig.h)

		include_directories(${CMAKE_CURRENT_BINARY_DIR})

		FILE(GLOB JPEG_LIB_HEADERS 
		  ${JPEG_LIB}/jerror.h
		  ${JPEG_LIB}/jmorecfg.h
		  ${JPEG_LIB}/jpeglib.h
		  ${JPEG_LIB}/jconfig.h
		)

		FILE(GLOB JPEG_LIB_SRC
		  ${JPEG_LIB}/jmemnobs.c
		  ${JPEG_LIB}/jaricom.c
		  ${JPEG_LIB}/jcapimin.c
		  ${JPEG_LIB}/jcapistd.c
		  ${JPEG_LIB}/jcarith.c
		  ${JPEG_LIB}/jccoefct.c
		  ${JPEG_LIB}/jccolor.c
		  ${JPEG_LIB}/jcdctmgr.c
		  ${JPEG_LIB}/jchuff.c
		  ${JPEG_LIB}/jcinit.c
		  ${JPEG_LIB}/jcmainct.c
		  ${JPEG_LIB}/jcmarker.c
		  ${JPEG_LIB}/jcmaster.c
		  ${JPEG_LIB}/jcomapi.c
		  ${JPEG_LIB}/jcparam.c
		  ${JPEG_LIB}/jcprepct.c
		  ${JPEG_LIB}/jcsample.c
		  ${JPEG_LIB}/jctrans.c
		  ${JPEG_LIB}/jdapimin.c
		  ${JPEG_LIB}/jdapistd.c
		  ${JPEG_LIB}/jdarith.c
		  ${JPEG_LIB}/jdatadst.c
		  ${JPEG_LIB}/jdatasrc.c
		  ${JPEG_LIB}/jdcoefct.c
		  ${JPEG_LIB}/jdcolor.c
		  ${JPEG_LIB}/jddctmgr.c
		  ${JPEG_LIB}/jdhuff.c
		  ${JPEG_LIB}/jdinput.c
		  ${JPEG_LIB}/jdmainct.c
		  ${JPEG_LIB}/jdmarker.c
		  ${JPEG_LIB}/jdmaster.c
		  ${JPEG_LIB}/jdmerge.c
		  ${JPEG_LIB}/jdpostct.c
		  ${JPEG_LIB}/jdsample.c
		  ${JPEG_LIB}/jdtrans.c
		  ${JPEG_LIB}/jerror.c
		  ${JPEG_LIB}/jfdctflt.c
		  ${JPEG_LIB}/jfdctfst.c
		  ${JPEG_LIB}/jfdctint.c
		  ${JPEG_LIB}/jidctflt.c
		  ${JPEG_LIB}/jidctfst.c
		  ${JPEG_LIB}/jidctint.c
		  ${JPEG_LIB}/jquant1.c
		  ${JPEG_LIB}/jquant2.c
		  ${JPEG_LIB}/jutils.c
		  ${JPEG_LIB}/jmemmgr.c
		  ${JPEG_LIB}/cderror.h
		  ${JPEG_LIB}/cdjpeg.h
		  ${JPEG_LIB}/jdct.h
		  ${JPEG_LIB}/jinclude.h
		  ${JPEG_LIB}/jmemsys.h
		  ${JPEG_LIB}/jpegint.h
		  ${JPEG_LIB}/jversion.h
		  ${JPEG_LIB}/transupp.h
		)

		add_library (libjpeg STATIC ${JPEG_LIB_SRC} ${JPEG_LIB_HEADERS})
		set(JPEG_BUNDLED_LIBRARIES libjpeg PARENT_SCOPE)
		set(JPEG_BUNDLED_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/jpeg" PARENT_SCOPE)
	endif(BUNDLED_JPEG)

	#-----------------------------------------------------------------
	# Build bundled cURL library
	#-----------------------------------------------------------------
	if(BUNDLED_CURL) # DLL
		ExternalProject_Add(bundled_curl
			SOURCE_DIR	${CMAKE_SOURCE_DIR}/libs/curl
			BINARY_DIR	${PROJECT_BINARY_DIR}/libs/curl
			CMAKE_ARGS	-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DBUILD_CURL_EXE=0 -DBUILD_CURL_TESTS=0 -DCURL_STATICLIB=1 -DCURL_USE_ARES=0 -DCURL_ZLIB=0 -DCMAKE_INSTALL_PREFIX=${PROJECT_BINARY_DIR}/curl
		)

		set(CURL_BUNDLED_LIBRARY "${PROJECT_BINARY_DIR}/curl/lib/libcurl${CMAKE_STATIC_LIBRARY_SUFFIX}" wsock32 ws2_32 PARENT_SCOPE)
		set(CURL_BUNDLED_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/curl/include" PARENT_SCOPE)
	endif(BUNDLED_CURL)

	#-----------------------------------------------------------------
	# Build bundled Lua 5.1 library
	#-----------------------------------------------------------------
	if(BUNDLED_LUA)
		set(LUA_LIB "${CMAKE_SOURCE_DIR}/libs/lua/src")
		FILE(GLOB LUA_LIB_SRC
			${LUA_LIB}/lapi.c
			${LUA_LIB}/lcode.c
			${LUA_LIB}/ldebug.c
			${LUA_LIB}/ldo.c
			${LUA_LIB}/ldump.c
			${LUA_LIB}/lfunc.c
			${LUA_LIB}/lgc.c
			${LUA_LIB}/llex.c
			${LUA_LIB}/lmem.c
			${LUA_LIB}/lobject.c
			${LUA_LIB}/lopcodes.c
			${LUA_LIB}/lparser.c
			${LUA_LIB}/lstate.c
			${LUA_LIB}/lstring.c
			${LUA_LIB}/ltable.c
			${LUA_LIB}/ltm.c
			${LUA_LIB}/lundump.c
			${LUA_LIB}/lvm.c
			${LUA_LIB}/lzio.c
			${LUA_LIB}/lauxlib.c
			${LUA_LIB}/lbaselib.c
			${LUA_LIB}/ldblib.c
			${LUA_LIB}/liolib.c
			${LUA_LIB}/lmathlib.c
			${LUA_LIB}/loslib.c
			${LUA_LIB}/ltablib.c
			${LUA_LIB}/lstrlib.c
			${LUA_LIB}/loadlib.c
			${LUA_LIB}/linit.c
		)

		FILE(GLOB LUA_LIB_HEADERS
			${LUA_LIB}/*.h
		)

		add_library(liblua STATIC ${LUA_LIB_SRC} ${LUA_LIB_HEADERS})
		set_target_properties(liblua
			PROPERTIES COMPILE_DEFINITIONS "LUA_ANSI"
		)

		set(LUA_BUNDLED_LIBRARIES liblua PARENT_SCOPE)
		set(LUA_BUNDLED_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/lua/src" PARENT_SCOPE)
	endif(BUNDLED_LUA)

	#-----------------------------------------------------------------
	# Copy bundled SDL library to the etl.exe location
	#-----------------------------------------------------------------
	if(BUNDLED_SDL) # DLL
		if(FEATURE_SDL2)
			file(COPY ${CMAKE_SOURCE_DIR}/libs/sdl2-windows/lib/x86/SDL2.dll DESTINATION ${CMAKE_BINARY_DIR})
			set(SDL32_BUNDLED_LIBRARIES
				"${CMAKE_SOURCE_DIR}/libs/sdl2-windows/lib/x86/SDL2.lib"
				"${CMAKE_SOURCE_DIR}/libs/sdl2-windows/lib/x86/SDL2main.lib" PARENT_SCOPE)
			set(SDL32_BUNDLED_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/sdl2/include" PARENT_SCOPE)
		else() #1.2
			file(COPY ${CMAKE_SOURCE_DIR}/libs/sdl-windows/lib/x86/SDL.dll DESTINATION ${CMAKE_BINARY_DIR})
			set(SDL32_BUNDLED_LIBRARIES
				"${CMAKE_SOURCE_DIR}/libs/sdl-windows/lib/x86/SDL.lib"
				"${CMAKE_SOURCE_DIR}/libs/sdl-windows/lib/x86/SDLmain.lib" PARENT_SCOPE)
			set(SDL32_BUNDLED_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/sdl/include" PARENT_SCOPE)
		endif()
	endif(BUNDLED_SDL)

	#-----------------------------------------------------------------
	# Build bundled OGG and Vorbis file library
	#-----------------------------------------------------------------
	if(BUNDLED_OGG_VORBIS)
		# OGG
		SET(OPATH "${CMAKE_SOURCE_DIR}/libs/ogg")

		SET(OGG_SRC ${OPATH}/src/bitwise.c ${OPATH}/src/framing.c)
		SET(OGG_HEADERS ${OPATH}/include/ogg/ogg.h ${OPATH}/include/ogg/os_types.h)

		INCLUDE_DIRECTORIES("${OPATH}/include")

		IF(MSVC)
		    ADD_DEFINITIONS(/D_UNICODE /DUNICODE)
		    LIST(APPEND OGG_SRC ${OPATH}/win32/ogg.def)
		ENDIF(MSVC)

		IF("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
	        # libogg expects configure to be called on linux to
	        # generate config_types.h
		    LIST(APPEND OGG_HEADERS ${OPATH}/include/ogg/config_types.h)
		    add_custom_command(OUTPUT ${OPATH}/include/ogg/config_types.h
		        COMMAND ${OPATH}/configure
		        DEPENDS ${OPATH}/include/ogg/ogg.h  # Hopefully if the libogg version changes, so does this file
													# so configure_types.h will be regenerated.
		        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
		    )
		ENDIF()

		add_library(bundled_ogg STATIC ${OGG_SRC} ${OGG_HEADERS})

		SET(VPATH "${CMAKE_SOURCE_DIR}/libs/vorbis")

		SET(VORBIS_SRC
		    ${VPATH}/lib/analysis.c
		    ${VPATH}/lib/bitrate.c
		    ${VPATH}/lib/block.c
		    ${VPATH}/lib/codebook.c
		    ${VPATH}/lib/envelope.c
		    ${VPATH}/lib/floor0.c
		    ${VPATH}/lib/floor1.c
		    ${VPATH}/lib/info.c
		    ${VPATH}/lib/lookup.c
		    ${VPATH}/lib/lpc.c
		    ${VPATH}/lib/lsp.c
		    ${VPATH}/lib/mapping0.c
		    ${VPATH}/lib/mdct.c
		    ${VPATH}/lib/psy.c
		    ${VPATH}/lib/registry.c
		    ${VPATH}/lib/res0.c
		    ${VPATH}/lib/sharedbook.c
		    ${VPATH}/lib/smallft.c
		    ${VPATH}/lib/synthesis.c
		    ${VPATH}/lib/vorbisenc.c
		    ${VPATH}/lib/window.c
		)

		SET(VORBIS_HEADERS 
		    ${VPATH}/lib/backends.h
		    ${VPATH}/lib/bitrate.h
		    ${VPATH}/lib/codebook.h
		    ${VPATH}/lib/codec_internal.h
		    ${VPATH}/lib/envelope.h
		    ${VPATH}/lib/modes/floor_all.h
		    ${VPATH}/lib/books/floor/floor_books.h
		    ${VPATH}/lib/highlevel.h
		    ${VPATH}/lib/lookup.h
		    ${VPATH}/lib/lookup_data.h
		    ${VPATH}/lib/lpc.h
		    ${VPATH}/lib/lsp.h
		    ${VPATH}/lib/masking.h
		    ${VPATH}/lib/mdct.h
		    ${VPATH}/lib/misc.h
		    ${VPATH}/lib/os.h
		    ${VPATH}/lib/psy.h
		    ${VPATH}/lib/modes/psych_11.h
		    ${VPATH}/lib/modes/psych_16.h
		    ${VPATH}/lib/modes/psych_44.h
		    ${VPATH}/lib/modes/psych_8.h
		    ${VPATH}/lib/registry.h
		    ${VPATH}/lib/books/coupled/res_books_stereo.h
		    ${VPATH}/lib/books/uncoupled/res_books_uncoupled.h
		    ${VPATH}/lib/modes/residue_16.h
		    ${VPATH}/lib/modes/residue_44.h
		    ${VPATH}/lib/modes/residue_44u.h
		    ${VPATH}/lib/modes/residue_8.h
		    ${VPATH}/lib/scales.h
		    ${VPATH}/lib/modes/setup_11.h
		    ${VPATH}/lib/modes/setup_16.h
		    ${VPATH}/lib/modes/setup_22.h
		    ${VPATH}/lib/modes/setup_32.h
		    ${VPATH}/lib/modes/setup_44.h
		    ${VPATH}/lib/modes/setup_44u.h
		    ${VPATH}/lib/modes/setup_8.h
		    ${VPATH}/lib/modes/setup_X.h
		    ${VPATH}/lib/smallft.h
		    ${VPATH}/lib/window.h
		)

		SET(VORBIS_PUB_HEADERS
		    ${VPATH}/include/vorbis/codec.h
		    ${VPATH}/include/vorbis/vorbisenc.h
		    ${VPATH}/include/vorbis/vorbisfile.h
		)

		INCLUDE_DIRECTORIES("${VPATH}/include" "${VPATH}/lib")

		IF(MSVC)
		    ADD_DEFINITIONS(/D_UNICODE /DUNICODE)
		    LIST(APPEND VORBIS_SRC ${VPATH}/win32/vorbis.def)
		ENDIF(MSVC)

		add_library(bundled_ogg_vorbis STATIC ${VORBIS_SRC} ${VORBIS_HEADERS} ${VORBIS_PUB_HEADERS})
		target_link_libraries(bundled_ogg_vorbis bundled_ogg)
		add_library(bundled_ogg_vorbis_file STATIC ${VPATH}/lib/vorbisfile.c ${VPATH}/include/vorbis/vorbisfile.h)
		target_link_libraries(bundled_ogg_vorbis_file bundled_ogg bundled_ogg_vorbis)

		set(OGG_BUNDLED_LIBRARIES bundled_ogg PARENT_SCOPE)
		set(OGG_BUNDLED_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/ogg/include" PARENT_SCOPE)
		set(OGG_VORBIS_BUNDLED_LIBRARIES bundled_ogg_vorbis bundled_ogg_vorbis_file PARENT_SCOPE)
		set(OGG_VORBIS_BUNDLED_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/vorbis/include" PARENT_SCOPE)
	endif(BUNDLED_OGG_VORBIS)
	
elseif(UNIX)

	if(CROSS_COMPILE32)
		set(CROSS_COMPILE32_FLAGS CFLAGS=-m32 LDFLAGS=-m32)
	else(CROSS_COMPILE32)
		set(CROSS_COMPILE32_FLAGS "")
	endif(CROSS_COMPILE32)

	#-----------------------------------------------------------------
	# Build bundled cURL library
	#-----------------------------------------------------------------
	if(BUNDLED_CURL)
		add_custom_command(OUTPUT ${CMAKE_SOURCE_DIR}/libs/curl/lib/.libs/libcurl.a
			COMMAND make clean || true
			COMMAND ${CROSS_COMPILE32_FLAGS} ./configure
			--enable-shared=no --enable-static=yes
			--without-libssh2 --enable-http --enable-ftp
			--disable-gopher --enable-file --disable-ldap
			--disable-dict --disable-telnet --disable-manual
			--enable-libgcc --disable-ipv6 --disable-ares
			--without-ssl --without-zlib --without-libidn
			--without-librtmp && make
			WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/libs/curl
		)
		add_custom_target(bundled_curl
			DEPENDS ${CMAKE_SOURCE_DIR}/libs/curl/lib/.libs/libcurl.a
		)
		set(CURL_BUNDLED_LIBRARY "${CMAKE_SOURCE_DIR}/libs/curl/lib/.libs/libcurl.a" PARENT_SCOPE)
		set(CURL_BUNDLED_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/curl/include" PARENT_SCOPE)
	endif(BUNDLED_CURL)
	
	#-----------------------------------------------------------------
	# Build bundled JPEG library
	#-----------------------------------------------------------------
	if(BUNDLED_JPEG)
		add_custom_command(OUTPUT ${CMAKE_SOURCE_DIR}/libs/jpeg/.libs/libjpeg.a
			COMMAND make clean || true
			COMMAND ${CROSS_COMPILE32_FLAGS} ./configure && make
			WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/libs/jpeg
		)
		add_custom_target(bundled_jpeg
			DEPENDS ${CMAKE_SOURCE_DIR}/libs/jpeg/.libs/libjpeg.a
		)
		set(JPEG_BUNDLED_LIBRARIES "${CMAKE_SOURCE_DIR}/libs/jpeg/.libs/libjpeg.a" PARENT_SCOPE)
		set(JPEG_BUNDLED_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/jpeg" PARENT_SCOPE)
	endif(BUNDLED_JPEG)

	#-----------------------------------------------------------------
	# Build bundled SDL library
	#-----------------------------------------------------------------
	if(BUNDLED_SDL)
		if(FEATURE_SDL2)
			add_custom_command(OUTPUT ${CMAKE_SOURCE_DIR}/libs/sdl2/build/.libs/libSDL2.a
				COMMAND make clean || true
				COMMAND ${CROSS_COMPILE32_FLAGS} ./configure && make
				WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/libs/sdl2
			)
			add_custom_target(bundled_sdl
				DEPENDS ${CMAKE_SOURCE_DIR}/libs/sdl2/build/.libs/libSDL2.a
			)
			if(CMAKE_SYSTEM MATCHES "Darwin")
				set(SDL32_BUNDLED_LIBRARIES ${SDL32_BUNDLED_LIBRARIES} "${CMAKE_SOURCE_DIR}/libs/sdl2/build/libSDL2main.a")
			endif(CMAKE_SYSTEM MATCHES "Darwin")
			set(SDL32_BUNDLED_LIBRARIES ${SDL32_BUNDLED_LIBRARIES} "${CMAKE_SOURCE_DIR}/libs/sdl2/build/.libs/libSDL2.a" PARENT_SCOPE)
			set(SDL32_BUNDLED_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/sdl2/include" PARENT_SCOPE)
		else() # SDL 1.3
			add_custom_command(OUTPUT ${CMAKE_SOURCE_DIR}/libs/sdl/build/.libs/libSDL.a
				COMMAND make clean || true
				# disable svga and directfb modules for cross-compiling on 64bit Debian Squeezy
				COMMAND ${CROSS_COMPILE32_FLAGS} ./configure --disable-cdrom --disable-video-svga --disable-cdrom --disable-video-directfb && make
				WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/libs/sdl
			)
			add_custom_target(bundled_sdl
				DEPENDS ${CMAKE_SOURCE_DIR}/libs/sdl/build/.libs/libSDL.a
			)
			if(CMAKE_SYSTEM MATCHES "Darwin")
				set(SDL32_BUNDLED_LIBRARIES ${SDL32_BUNDLED_LIBRARIES} "${CMAKE_SOURCE_DIR}/libs/sdl/build/.libs/libSDLmain.a")
			endif(CMAKE_SYSTEM MATCHES "Darwin")
			set(SDL32_BUNDLED_LIBRARIES ${SDL32_BUNDLED_LIBRARIES} "${CMAKE_SOURCE_DIR}/libs/sdl/build/.libs/libSDL.a" PARENT_SCOPE)
			set(SDL32_BUNDLED_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/sdl/include" PARENT_SCOPE)
		endif()
	endif(BUNDLED_SDL)

	#-----------------------------------------------------------------
	# Build bundled Lua 5.1 library
	#-----------------------------------------------------------------
	# NOTE: the posix32bit target was added into the Lua Makefiles
	if(BUNDLED_LUA)
		if(CMAKE_SYSTEM MATCHES "OpenBSD*")
			set(LUA_MAKE_TARGET "bsd")
		else()
			if(NOT CROSS_COMPILE32)
				set(LUA_MAKE_TARGET "posix")
			else()
				set(LUA_MAKE_TARGET "posix32bit")
			endif()
		endif()
		add_custom_command(OUTPUT ${CMAKE_SOURCE_DIR}/libs/lua/src/liblua.a
			COMMAND make clean || true
			COMMAND ${CROSS_COMPILE32_FLAGS} make ${LUA_MAKE_TARGET}
			WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/libs/lua
		)
		set(LUA_BUNDLED_LIBRARIES "${CMAKE_SOURCE_DIR}/libs/lua/src/liblua.a" PARENT_SCOPE)
		set(LUA_BUNDLED_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/lua/src" PARENT_SCOPE)

		add_custom_target(bundled_lua
			DEPENDS ${CMAKE_SOURCE_DIR}/libs/lua/src/liblua.a
		)
	endif(BUNDLED_LUA)

	#-----------------------------------------------------------------
	# Build bundled OGG and Vorbis file library
	#-----------------------------------------------------------------
	if(BUNDLED_OGG_VORBIS)
		# OGG
		add_custom_command(OUTPUT ${CMAKE_SOURCE_DIR}/libs/ogg/src/.libs/libogg.a
			COMMAND make clean || true
			COMMAND ${CROSS_COMPILE32_FLAGS} ./configure && make
			WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/libs/ogg
		)
		add_custom_target(bundled_ogg
			DEPENDS ${CMAKE_SOURCE_DIR}/libs/ogg/src/.libs/libogg.a
		)
		set(OGG_BUNDLED_LIBRARIES "${CMAKE_SOURCE_DIR}/libs/ogg/src/.libs/libogg.a" PARENT_SCOPE)
		set(OGG_BUNDLED_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/ogg/include" PARENT_SCOPE)

		# OGG Vorbis File
		if(CROSS_COMPILE32_FLAGS)
			set(CFLAGS "-m32 -I${CMAKE_SOURCE_DIR}/libs/ogg/include")
			set(LDFLAGS "-m32 -L${CMAKE_SOURCE_DIR}/libs/ogg/src/.libs")
		else()
			set(CFLAGS "-I${CMAKE_SOURCE_DIR}/libs/ogg/include")
			set(LDFLAGS "-L${CMAKE_SOURCE_DIR}/libs/ogg/src/.libs")
		endif()

		add_custom_command(
			OUTPUT ${CMAKE_SOURCE_DIR}/libs/vorbis/lib/.libs/libvorbisfile.a
			COMMAND make clean || true
			COMMAND eval \"CFLAGS=${CFLAGS} LDFLAGS=${LDFLAGS} ./configure --disable-oggtest && make\"
			WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/libs/vorbis
		)
		add_custom_target(bundled_ogg_vorbis
			DEPENDS ${CMAKE_SOURCE_DIR}/libs/vorbis/lib/.libs/libvorbisfile.a
			DEPENDS ${CMAKE_SOURCE_DIR}/libs/vorbis/lib/.libs/libvorbis.a
		)
		set(OGG_VORBIS_BUNDLED_LIBRARIES "${CMAKE_SOURCE_DIR}/libs/vorbis/lib/.libs/libvorbisfile.a" "${CMAKE_SOURCE_DIR}/libs/vorbis/lib/.libs/libvorbis.a" PARENT_SCOPE)
		set(OGG_VORBIS_BUNDLED_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/vorbis/include" PARENT_SCOPE)

		add_dependencies(bundled_ogg_vorbis bundled_ogg)
	endif(BUNDLED_OGG_VORBIS)
endif()

#-----------------------------------------------------------------
# Build bundled GLEW library
#-----------------------------------------------------------------
if(BUNDLED_GLEW)
	include(${CMAKE_SOURCE_DIR}/libs/glew/CMakeLists.txt)
	set(BUNDLED_GLEW_LIBRARIES glew PARENT_SCOPE)
	set(BUNDLED_GLEW_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/glew/include" PARENT_SCOPE)
endif(BUNDLED_GLEW)
