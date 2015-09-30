include(ExternalProject)
include(CheckIncludeFile)

set(LIBS_BINARYDIR_DIR ${PROJECT_BINARY_DIR}/libs)

if(WIN32)
	#-----------------------------------------------------------------
	# Build bundled JPEG library
	#-----------------------------------------------------------------
	if(BUNDLED_JPEG) # static
		check_include_file ( stddef.h HAVE_STDDEF_H )
		check_include_file ( stdlib.h HAVE_STDLIB_H )

		set(JPEG_LIB "${CMAKE_CURRENT_LIST_DIR}/jpegturbo")
		if(MSVC)
			add_definitions ( -D_CRT_SECURE_NO_WARNINGS )
		endif()

		if(WIN32 AND NOT CYGWIN)
			set(TWO_FILE_COMMANDLINE true)
		endif()
		set(WITH_JPEG8 true)

		configure_file (${JPEG_LIB}/config.h.cmake ${JPEG_LIB}/config.h)
		configure_file (${JPEG_LIB}/jconfig.h.cmake ${JPEG_LIB}/jconfig.h)
		configure_file (${JPEG_LIB}/jconfigint.h.cmake ${JPEG_LIB}/jconfigint.h)

		#include_directories(${CMAKE_CURRENT_BINARY_DIR})
		FILE(GLOB JPEG_LIB_HEADERS
			${JPEG_LIB}/config.h
			${JPEG_LIB}/jerror.h
			${JPEG_LIB}/jmorecfg.h
			${JPEG_LIB}/jpeglib.h
			${JPEG_LIB}/jconfig.h
			${JPEG_LIB}/jconfigint.h
			${JPEG_LIB}/turbojpeg.h
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
			${JPEG_LIB}/jcphuff.c
			${JPEG_LIB}/jcprepct.c
			${JPEG_LIB}/jcsample.c
			${JPEG_LIB}/jctest.c
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
			${JPEG_LIB}/jdphuff.c
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
			${JPEG_LIB}/jidctred.c
			${JPEG_LIB}/jmemmgr.c
			${JPEG_LIB}/jmemnobs.c
			${JPEG_LIB}/jquant1.c
			${JPEG_LIB}/jquant2.c
			${JPEG_LIB}/jsimd_none.c
			${JPEG_LIB}/jutils.c
			${JPEG_LIB}/turbojpeg.c
			${JPEG_LIB}/cderror.h
			${JPEG_LIB}/cdjpeg.h
			${JPEG_LIB}/jdct.h
			${JPEG_LIB}/jinclude.h
			${JPEG_LIB}/jmemsys.h
			${JPEG_LIB}/jpegint.h
			${JPEG_LIB}/jpeg_nbits_table.h
			${JPEG_LIB}/jversion.h
			${JPEG_LIB}/transupp.h
		)

		add_library (bundled_jpeg STATIC ${JPEG_LIB_SRC} ${JPEG_LIB_HEADERS})
		set(JPEG_BUNDLED_LIBRARIES bundled_jpeg)
		set(JPEG_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/jpegturbo")
	endif(BUNDLED_JPEG)


	#-----------------------------------------------------------------
	# Build bundled cURL library
	#-----------------------------------------------------------------
	if(BUNDLED_CURL) # DLL
		ExternalProject_Add(bundled_curl
			SOURCE_DIR	${CMAKE_CURRENT_LIST_DIR}/curl
			BINARY_DIR	${LIBS_BINARYDIR_DIR}/curl
			CMAKE_ARGS	-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS} -DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG} -DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE} -DBUILD_CURL_EXE=0 -DBUILD_CURL_TESTS=0 -DCURL_STATICLIB=1 -DCURL_USE_ARES=0 -DCURL_ZLIB=0 -DCMAKE_INSTALL_PREFIX=${PROJECT_BINARY_DIR}/curl
			INSTALL_COMMAND  ""
		)

		ExternalProject_Get_Property(bundled_curl binary_dir)

		if(VSTUDIO)
			set(CURL_BUNDLED_LIBRARY optimized "${binary_dir}/lib/Release/libcurl${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${binary_dir}/lib/Debug/libcurl${CMAKE_STATIC_LIBRARY_SUFFIX}")
		elseif(MINGW)
			set(CURL_BUNDLED_LIBRARY "${binary_dir}/lib/libcurl${CMAKE_STATIC_LIBRARY_SUFFIX}")
		else(VSTUDIO)
			set(CURL_BUNDLED_LIBRARY "${binary_dir}/libcurl${CMAKE_STATIC_LIBRARY_SUFFIX}")
		endif(VSTUDIO)

		set(CURL_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/curl/include")
	endif(BUNDLED_CURL)

	#-----------------------------------------------------------------
	# Build bundled Lua library
	#-----------------------------------------------------------------
	if(BUNDLED_LUA)
		set(LUA_LIB "${CMAKE_CURRENT_LIST_DIR}/lua/src")
		FILE(GLOB LUA_LIB_SRC
			#core
			${LUA_LIB}/lapi.c
			${LUA_LIB}/lcode.c
			${LUA_LIB}/lctype.c
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
			#lib
			${LUA_LIB}/lauxlib.c
			${LUA_LIB}/lbaselib.c
			${LUA_LIB}/lbitlib.c
			${LUA_LIB}/lcorolib.c
			${LUA_LIB}/ldblib.c
			${LUA_LIB}/linit.c
			${LUA_LIB}/liolib.c
			${LUA_LIB}/lmathlib.c
			${LUA_LIB}/loadlib.c
			${LUA_LIB}/loslib.c
			${LUA_LIB}/lstrlib.c
			${LUA_LIB}/ltablib.c
			${LUA_LIB}/lutf8lib.c
		)

		FILE(GLOB LUA_LIB_HEADERS
			${LUA_LIB}/*.h
		)

		add_library(bundled_lua STATIC ${LUA_LIB_SRC} ${LUA_LIB_HEADERS})

		# If LUA_ANSI is enabled on windows the library loading functionality is disabled
		if(NOT WIN32)
			set_target_properties(bundled_lua
				PROPERTIES COMPILE_DEFINITIONS "LUA_ANSI"
			)
		endif()

		set(LUA_BUNDLED_LIBRARIES bundled_lua)
		set(LUA_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/lua/src")
	endif(BUNDLED_LUA)

	#-----------------------------------------------------------------
	# Copy bundled SDL library to the etl.exe location
	#-----------------------------------------------------------------
	if(BUNDLED_SDL) # DLL
		add_custom_target(bundled_sdl) # Dummy target just so cmake does not print warnings
		# Enable the SDL2main when the windows main function has been removed....
		if(WIN64)
			file(COPY ${CMAKE_CURRENT_LIST_DIR}/sdl2-windows/lib/x64/SDL2.dll DESTINATION ${CMAKE_BINARY_DIR})
			install(FILES "${CMAKE_CURRENT_LIST_DIR}/sdl2-windows/lib/x64/SDL2.dll" DESTINATION "${INSTALL_DEFAULT_BINDIR}")
			set(SDL32_BUNDLED_LIBRARIES
				"${CMAKE_CURRENT_LIST_DIR}/sdl2-windows/lib/x64/SDL2.lib"
				#"${CMAKE_CURRENT_LIST_DIR}/sdl2-windows/lib/x64/SDL2main.lib"
			)
			set(SDL32_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/sdl2/include")
		else(WIN64)
			file(COPY ${CMAKE_CURRENT_LIST_DIR}/sdl2-windows/lib/x86/SDL2.dll DESTINATION ${CMAKE_BINARY_DIR})
			install(FILES "${CMAKE_CURRENT_LIST_DIR}/sdl2-windows/lib/x86/SDL2.dll" DESTINATION "${INSTALL_DEFAULT_BINDIR}")
			set(SDL32_BUNDLED_LIBRARIES
				"${CMAKE_CURRENT_LIST_DIR}/sdl2-windows/lib/x86/SDL2.lib"
				#"${CMAKE_CURRENT_LIST_DIR}/sdl2-windows/lib/x86/SDL2main.lib"
			)
			set(SDL32_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/sdl2/include")
		endif(WIN64)
	endif(BUNDLED_SDL)

	#-----------------------------------------------------------------
	# Build bundled OGG and Vorbis file library
	#-----------------------------------------------------------------
	if(BUNDLED_OGG_VORBIS)
		# OGG
		SET(OPATH "${CMAKE_CURRENT_LIST_DIR}/ogg")

		SET(OGG_SRC ${OPATH}/src/bitwise.c ${OPATH}/src/framing.c)
		SET(OGG_HEADERS ${OPATH}/include/ogg/ogg.h ${OPATH}/include/ogg/os_types.h)

		INCLUDE_DIRECTORIES("${OPATH}/include")

		IF(MSVC)
			#ADD_DEFINITIONS(/D_UNICODE /DUNICODE)
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

		SET(VPATH "${CMAKE_CURRENT_LIST_DIR}/vorbis")

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
			#ADD_DEFINITIONS(/D_UNICODE /DUNICODE)
		    LIST(APPEND VORBIS_SRC ${VPATH}/win32/vorbis.def)
		ENDIF(MSVC)

		add_library(bundled_ogg_vorbis STATIC ${VORBIS_SRC} ${VORBIS_HEADERS} ${VORBIS_PUB_HEADERS})
		target_link_libraries(bundled_ogg_vorbis bundled_ogg)
		add_library(bundled_ogg_vorbis_file STATIC ${VPATH}/lib/vorbisfile.c ${VPATH}/include/vorbis/vorbisfile.h)
		target_link_libraries(bundled_ogg_vorbis_file bundled_ogg bundled_ogg_vorbis)

		if(MSVC)
			set(VORB_UNI "_UNICODE;UNICODE")
			set_target_properties(bundled_ogg PROPERTIES
				COMPILE_DEFINITIONS "${VORB_UNI}"
			)
			set_target_properties(bundled_ogg_vorbis PROPERTIES
				COMPILE_DEFINITIONS "${VORB_UNI}"
			)
			set_target_properties(bundled_ogg_vorbis_file PROPERTIES
				COMPILE_DEFINITIONS "${VORB_UNI}"
			)
		endif(MSVC)

		set(OGG_BUNDLED_LIBRARIES bundled_ogg)
		set(OGG_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/ogg/include")
		set(OGG_VORBIS_BUNDLED_LIBRARIES bundled_ogg_vorbis bundled_ogg_vorbis_file)
		set(OGG_VORBIS_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/vorbis/include")
	endif(BUNDLED_OGG_VORBIS)

elseif(UNIX)

	if(CROSS_COMPILE32)
		set(CROSS_COMPILE32_FLAGS CFLAGS=-m32 LDFLAGS=-m32)
	else(CROSS_COMPILE32)

		# when we don't cross compile we have to enable position independant code '-fPIC' for all bundled libs
		# see http://stackoverflow.com/questions/7216244/why-is-fpic-absolutely-necessary-on-64-and-not-on-32bit-platforms
		# let's misuse CROSS_COMPILE32_FLAGS var (for 64bit) to set our flag. FIXME: rename to CROSS_COMPILE_OPTIONAL_FLAGS?
		# notes: - cflag -mcmodel=large might be an option too
		#        - this has to be done in all dependant CMakeLists-txt files see glew/CMakeLists.txt
		set(CROSS_COMPILE32_FLAGS "CFLAGS=-fPIC")

	endif(CROSS_COMPILE32)

	#-----------------------------------------------------------------
	# Build bundled cURL library
	#-----------------------------------------------------------------
	if(BUNDLED_CURL)
		add_custom_command(OUTPUT ${CMAKE_CURRENT_LIST_DIR}/curl/lib/.libs/libcurl.a
			COMMAND make clean || true
			COMMAND ${CROSS_COMPILE32_FLAGS} ./configure
			--enable-shared=no --enable-static=yes
			--without-libssh2 --enable-http --enable-ftp
			--disable-gopher --enable-file --disable-ldap
			--disable-dict --disable-telnet --disable-manual
			--enable-libgcc --disable-ipv6 --disable-ares
			--without-ssl --without-zlib --without-libidn
			--without-librtmp && make
			WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/curl
		)
		add_custom_target(bundled_curl
			DEPENDS ${CMAKE_CURRENT_LIST_DIR}/curl/lib/.libs/libcurl.a
		)
		set(CURL_BUNDLED_LIBRARY "${CMAKE_CURRENT_LIST_DIR}/curl/lib/.libs/libcurl.a")
		set(CURL_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/curl/include")
	endif(BUNDLED_CURL)

	#-----------------------------------------------------------------
	# Build bundled JPEG library
	#-----------------------------------------------------------------
	if(BUNDLED_JPEG)
		if(CROSS_COMPILE32)
			if(APPLE)
				SET(JPEG_TURBO_BUILD ${CROSS_COMPILE32_FLAGS} ./configure --with-jpeg8 --build i686-apple-darwin && make)
			else()
				SET(JPEG_TURBO_BUILD ${CROSS_COMPILE32_FLAGS} ./configure --with-jpeg8 --build i686-pc-linux-gnu && make)
			endif()
		else(CROSS_COMPILE32)
			if(APPLE)
				SET(JPEG_TURBO_BUILD ${CROSS_COMPILE32_FLAGS} ./configure --with-jpeg8 --build x86_64-apple-darwin && make)
			else()
				SET(JPEG_TURBO_BUILD ${CROSS_COMPILE32_FLAGS} ./configure --with-jpeg8 && make)
			endif()
		endif()

		add_custom_command(OUTPUT ${CMAKE_CURRENT_LIST_DIR}/jpegturbo/.libs/libturbojpeg.a
			COMMAND make clean || true
			COMMAND ${JPEG_TURBO_BUILD}
			WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/jpegturbo
		)

		add_custom_target(bundled_jpeg
			DEPENDS ${CMAKE_CURRENT_LIST_DIR}/jpegturbo/.libs/libturbojpeg.a
		)
		set(JPEG_BUNDLED_LIBRARIES "${CMAKE_CURRENT_LIST_DIR}/jpegturbo/.libs/libturbojpeg.a")
		set(JPEG_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/jpegturbo")
	endif(BUNDLED_JPEG)

	#-----------------------------------------------------------------
	# Build bundled SDL library
	#-----------------------------------------------------------------
	if(BUNDLED_SDL)
		add_custom_command(OUTPUT ${CMAKE_CURRENT_LIST_DIR}/sdl2/build/.libs/libSDL2.a
			COMMAND make clean || true
			COMMAND ${CROSS_COMPILE32_FLAGS} ./configure && make
			WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/sdl2
		)
		add_custom_target(bundled_sdl
			DEPENDS ${CMAKE_CURRENT_LIST_DIR}/sdl2/build/.libs/libSDL2.a
		)
		if(CMAKE_SYSTEM MATCHES "Darwin")
			set(SDL32_BUNDLED_LIBRARIES ${SDL32_BUNDLED_LIBRARIES} "${CMAKE_CURRENT_LIST_DIR}/sdl2/build/libSDL2main.a")
		endif(CMAKE_SYSTEM MATCHES "Darwin")
		set(SDL32_BUNDLED_LIBRARIES ${SDL32_BUNDLED_LIBRARIES} "${CMAKE_CURRENT_LIST_DIR}/sdl2/build/.libs/libSDL2.a")
		set(SDL32_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/sdl2/include")
	endif(BUNDLED_SDL)

	#-----------------------------------------------------------------
	# Build bundled Lua library
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
		add_custom_command(OUTPUT ${CMAKE_CURRENT_LIST_DIR}/lua/src/liblua.a
			COMMAND make clean || true
			COMMAND ${CROSS_COMPILE32_FLAGS} make ${LUA_MAKE_TARGET}
			WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/lua/src
		)
		set(LUA_BUNDLED_LIBRARIES "${CMAKE_CURRENT_LIST_DIR}/lua/src/liblua.a")
		set(LUA_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/lua/src")

		add_custom_target(bundled_lua
			DEPENDS ${CMAKE_CURRENT_LIST_DIR}/lua/src/liblua.a
		)
	endif(BUNDLED_LUA)

	#-----------------------------------------------------------------
	# Build bundled OGG and Vorbis file library
	#-----------------------------------------------------------------
	if(BUNDLED_OGG_VORBIS)
		# OGG
		add_custom_command(OUTPUT ${CMAKE_CURRENT_LIST_DIR}/ogg/src/.libs/libogg.a
			COMMAND make clean || true
			COMMAND ./autogen.sh
			COMMAND ${CROSS_COMPILE32_FLAGS} ./configure && make
			WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/ogg
		)
		add_custom_target(bundled_ogg
			DEPENDS ${CMAKE_CURRENT_LIST_DIR}/ogg/src/.libs/libogg.a
		)
		set(OGG_BUNDLED_LIBRARIES "${CMAKE_CURRENT_LIST_DIR}/ogg/src/.libs/libogg.a")
		set(OGG_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/ogg/include")

		# OGG Vorbis File
		set(CFLAGS "${CFLAGS} -I${CMAKE_CURRENT_LIST_DIR}/ogg/include")
		set(LDFLAGS "${LDFLAGS} -L${CMAKE_CURRENT_LIST_DIR}/ogg/src/.libs")

		# the above set of CFLAGS and LDFLAGS don't trigger on some systems
		# ensure vorbis configure uses our bundled ogg see --with-ogg-includes & --with-ogg-libraries
		add_custom_command(
			OUTPUT ${CMAKE_CURRENT_LIST_DIR}/vorbis/lib/.libs/libvorbisfile.a
			COMMAND make clean || true
			COMMAND ${CROSS_COMPILE32_FLAGS} ./configure --disable-oggtest --with-ogg-includes=${CMAKE_CURRENT_LIST_DIR}/ogg/include --with-ogg-libraries=${CMAKE_CURRENT_LIST_DIR}/ogg/src/.libs && make
			WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/vorbis
		)
		add_custom_target(bundled_ogg_vorbis_file
			DEPENDS ${CMAKE_CURRENT_LIST_DIR}/vorbis/lib/.libs/libvorbisfile.a
		)
		add_custom_target(bundled_ogg_vorbis
			DEPENDS ${CMAKE_CURRENT_LIST_DIR}/vorbis/lib/.libs/libvorbis.a
		)
		add_dependencies(bundled_ogg_vorbis_file bundled_ogg)
		add_dependencies(bundled_ogg_vorbis bundled_ogg_vorbis_file)
		set(OGG_VORBIS_BUNDLED_LIBRARIES "${CMAKE_CURRENT_LIST_DIR}/vorbis/lib/.libs/libvorbisfile.a" "${CMAKE_CURRENT_LIST_DIR}/vorbis/lib/.libs/libvorbis.a")
		set(OGG_VORBIS_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/vorbis/include")
	endif(BUNDLED_OGG_VORBIS)
endif()

#-----------------------------------------------------------------
# Build bundled GLEW library
#-----------------------------------------------------------------
if(BUNDLED_GLEW)
	include(${CMAKE_CURRENT_LIST_DIR}/glew/CMakeLists.txt)
	set(BUNDLED_GLEW_LIBRARIES bundled_glew)
	set(BUNDLED_GLEW_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/glew/include")
endif(BUNDLED_GLEW)

#-----------------------------------------------------------------
# Build bundled Freetype library
#-----------------------------------------------------------------
if(BUNDLED_FREETYPE)
	ExternalProject_Add(bundled_freetype
		SOURCE_DIR	${CMAKE_CURRENT_LIST_DIR}/freetype
		BINARY_DIR	${LIBS_BINARYDIR_DIR}/freetype
		CMAKE_ARGS	-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS} -DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG} -DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE} -DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}
		INSTALL_COMMAND  ""
	)

	ExternalProject_Get_Property(bundled_freetype binary_dir)

	if(VSTUDIO)
		set(BUNDLED_FREETYPE_LIBRARIES optimized "${binary_dir}/Release/freetype${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${binary_dir}/Debug/freetype${CMAKE_STATIC_LIBRARY_SUFFIX}")
	elseif(NMAKE_BUILD)
		set(BUNDLED_FREETYPE_LIBRARIES "${binary_dir}/freetype${CMAKE_STATIC_LIBRARY_SUFFIX}")
	else(VSTUDIO)
		set(BUNDLED_FREETYPE_LIBRARIES "${binary_dir}/libfreetype${CMAKE_STATIC_LIBRARY_SUFFIX}")
	endif(VSTUDIO)
	set(BUNDLED_FREETYPE_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/freetype/include")
endif(BUNDLED_FREETYPE)

if(BUNDLED_THEORA)
	FILE(GLOB THEORA_SRC
		"${CMAKE_CURRENT_LIST_DIR}/theora/lib/*.c"
		"${CMAKE_CURRENT_LIST_DIR}/theora/lib/*.h"
	)

	# This makes the MSVC build a happier
	LIST(REMOVE_ITEM THEORA_SRC ${CMAKE_CURRENT_LIST_DIR}/theora/lib/encoder_disabled.c)

	if(32BITS)
		add_definitions("-DOC_X86_ASM")
		if(MSVC)
			FILE(GLOB THEORA_ASM_SRC
				"${CMAKE_CURRENT_LIST_DIR}/theora/lib/x86_vc/*.c"
				"${CMAKE_CURRENT_LIST_DIR}/theora/lib/x86_vc/*.h"
			)
		else()
			FILE(GLOB THEORA_ASM_SRC
				"${CMAKE_CURRENT_LIST_DIR}/theora/lib/x86/*.c"
				"${CMAKE_CURRENT_LIST_DIR}/theora/lib/x86/*.h"
			)
		endif()

		LIST(APPEND THEORA_SRC ${THEORA_ASM_SRC})
	endif()

	include_directories("${CMAKE_CURRENT_LIST_DIR}/theora/include")
	add_library(bundled_theora STATIC ${THEORA_SRC})
	#target_include_directories(bundled_theora PUBLIC "${CMAKE_CURRENT_LIST_DIR}/theora/include")
	#if(UNIX AND NOT APPLE)
	#	target_include_directories(bundled_theora PUBLIC "${CMAKE_CURRENT_LIST_DIR}/ogg/include")
	#endif()

	set(THEORA_BUNDLED_LIBRARIES bundled_theora)
	set(THEORA_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/theora/include")
endif()

#-----------------------------------------------------------------
# Build bundled JANSSON library
#-----------------------------------------------------------------
if(BUNDLED_JANSSON)
	ExternalProject_Add(bundled_jansson
		SOURCE_DIR	${CMAKE_CURRENT_LIST_DIR}/jansson
		BINARY_DIR	${LIBS_BINARYDIR_DIR}/jansson
		CMAKE_ARGS	-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}  -DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG} -DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE} -DCMAKE_C_FLAGS=${CMAKE_C_FLAGS} -DJANSSON_WITHOUT_TESTS=1 -DBUILD_DOCS=0 -DJANSSON_STATIC_CRT=1 -DJANSSON_BUILD_DOCS=0
		INSTALL_COMMAND  ""
	)

	ExternalProject_Get_Property(bundled_jansson binary_dir)

	if(WIN32 AND DEBUG_BUILD)
		set(jansson_name "jansson_d${CMAKE_STATIC_LIBRARY_SUFFIX}")
	else(WIN32 AND DEBUG_BUILD)
		set(jansson_name "jansson${CMAKE_STATIC_LIBRARY_SUFFIX}")
	endif(WIN32 AND DEBUG_BUILD)

	if(VSTUDIO)
		set(BUNDLED_JANSSON_LIBRARY optimized "${binary_dir}/lib/Release/jansson${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${binary_dir}/lib/Debug/jansson_d${CMAKE_STATIC_LIBRARY_SUFFIX}")
	elseif(NMAKE_BUILD)
		set(BUNDLED_JANSSON_LIBRARY "${binary_dir}/lib/${jansson_name}")
	else(VSTUDIO)
		set(BUNDLED_JANSSON_LIBRARY "${binary_dir}/lib/lib${jansson_name}")
	endif(VSTUDIO)
	set(BUNDLED_JANSSON_INCLUDE_DIR "${binary_dir}/include")
endif(BUNDLED_JANSSON)
