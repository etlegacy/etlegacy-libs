include(ExternalProject)
include(CheckIncludeFile)

set(LIBS_BINARYDIR_DIR ${PROJECT_BINARY_DIR}/libs)
set(LIBS_DOWNLOAD_DIR ${PROJECT_BINARY_DIR}/downloads)

if(BUNDLED_OPENSSL)
	find_program(NASM_EXECUTABLE nasm)
	if(NOT NASM_EXECUTABLE)
		message(FATAL_ERROR "NASM not found")
	endif()

	FIND_PACKAGE(perl REQUIRED)
	if(NOT PERL_FOUND)
		message(FATAL_ERROR "Perl not found")
	endif()

	if(WIN32)
		if(64BITS)
			set(openssl_plat VC-WIN64)
			# set(curl_plat x64)
		else()
			set(openssl_plat VC-WIN32)
			# set(curl_plat x86)
		endif()
	endif()
endif()

#CMAKE_DEBUG_POSTFIX

if(WIN32)
	#-----------------------------------------------------------------
	# Build bundled JPEG library
	#-----------------------------------------------------------------
	if(BUNDLED_JPEG AND BUILD_CLIENT) # static
		check_include_file(stddef.h HAVE_STDDEF_H)
		check_include_file(stdlib.h HAVE_STDLIB_H)

		set(JPEG_LIB "${CMAKE_CURRENT_LIST_DIR}/jpegturbo")
		if(MSVC)
			add_definitions(-D_CRT_SECURE_NO_WARNINGS)
		endif()

		if(WIN32 AND NOT CYGWIN)
			set(TWO_FILE_COMMANDLINE true)
		endif()
		set(WITH_JPEG8 true)

		configure_file (${JPEG_LIB}/jconfig.h.cmake ${JPEG_LIB}/jconfig.h)
		configure_file (${JPEG_LIB}/jconfigint.h.cmake ${JPEG_LIB}/jconfigint.h)

		#include_directories(${CMAKE_CURRENT_BINARY_DIR})
		FILE(GLOB JPEG_LIB_HEADERS
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

		add_library(bundled_jpeg STATIC ${JPEG_LIB_SRC} ${JPEG_LIB_HEADERS})
		set(JPEG_BUNDLED_LIBRARIES bundled_jpeg)
		set(JPEG_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/jpegturbo")
		set_target_properties(bundled_jpeg PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
	endif()

	if(BUNDLED_OPENSSL AND (BUILD_CLIENT OR BUILD_SERVER))
		set(OPENSSL_PREFIX "${CMAKE_BINARY_DIR}/openssl/build")
		set(OPENSSL_CONFIGURE "${PERL_EXECUTABLE}" Configure "${openssl_plat}" "--prefix=${OPENSSL_PREFIX}" "--openssldir=${OPENSSL_PREFIX}" no-shared no-unit-test -static)
		set(OPENSSL_BUILD nmake)
		set(OPENSSL_INSTALL nmake install)
		ExternalProject_Add(bundled_openssl
			# Use github archive instead of the one hosted on openssl.org because of CMake bug #13251
			#URL_MD5 "9e380f6f9cc497bd2f47c944019239ac"
			#GIT_REPOSITORY "https://github.com/openssl/openssl.git"
			DOWNLOAD_DIR ${LIBS_DOWNLOAD_DIR}/openssl
			URL https://github.com/openssl/openssl/archive/OpenSSL_1_1_0j.tar.gz
			SOURCE_DIR "${CMAKE_BINARY_DIR}/openssl"
			BUILD_IN_SOURCE 1
			CONFIGURE_COMMAND ${OPENSSL_CONFIGURE}
			BUILD_COMMAND ${OPENSSL_BUILD}
			INSTALL_COMMAND ${OPENSSL_INSTALL}
		)
		set(OPENSSL_BUNDLED_INCLUDE_DIR "${OPENSSL_PREFIX}/include")
		set(OPENSSL_BUNDLED_LIBRARY "${OPENSSL_PREFIX}/lib/libcrypto.lib" "${OPENSSL_PREFIX}/lib/libssl.lib")
		set_target_properties(bundled_openssl PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
	else()
		add_custom_target(bundled_openssl)
		set_target_properties(bundled_openssl PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
	endif()

	#-----------------------------------------------------------------
	# Build bundled cURL library
	#-----------------------------------------------------------------
	if(BUNDLED_CURL AND (BUILD_CLIENT OR BUILD_SERVER)) # DLL
		# -DHTTP_ONLY=1
		ExternalProject_Add(bundled_curl
			DEPENDS bundled_openssl
			SOURCE_DIR	${CMAKE_CURRENT_LIST_DIR}/curl
			BINARY_DIR	${LIBS_BINARYDIR_DIR}/curl
			CMAKE_ARGS	-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
			-DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG} -DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}
			-DBUILD_CURL_EXE=0 -DBUILD_SHARED_LIBS=0 -DENABLE_ARES=0 -DENABLE_THREADED_RESOLVER=1 -DENABLE_DEBUG=0
			-DENABLE_CURLDEBUG=0 -DBUILD_TESTING=0 -DENABLE_IPV6=1 -DENABLE_MANUAL=0 -DCMAKE_USE_LIBSSH2=0
			-DUSE_NGHTTP2=0 -DCURL_WINDOWS_SSPI=0 -DCURL_ZLIB=1 -DCMAKE_USE_GSSAPI=0
			-DCURL_DISABLE_LDAP=1 -DCURL_DISABLE_LDAPS=1 -DCURL_DISABLE_TELNET=1 -DCURL_DISABLE_DICT=1
			-DCURL_DISABLE_FILE=1 -DCURL_DISABLE_TFTP=1 -DCURL_DISABLE_RTSP=1 -DCURL_DISABLE_POP3=1 -DCURL_DISABLE_IMAP=1
			-DCURL_DISABLE_SMTP=1 -DCURL_DISABLE_GOPHER=1
			-DOPENSSL_ROOT_DIR=${OPENSSL_PREFIX} -DCMAKE_USE_OPENSSL=${FEATURE_OPENSSL}
			-DENABLE_UNIX_SOCKETS=1 -DCMAKE_INSTALL_PREFIX=${PROJECT_BINARY_DIR}/curl
			INSTALL_COMMAND  ""
		)

		ExternalProject_Get_Property(bundled_curl binary_dir)

		if(VSTUDIO)
			set(CURL_BUNDLED_LIBRARY optimized "${binary_dir}/lib/Release/libcurl${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${binary_dir}/lib/Debug/libcurl-d${CMAKE_STATIC_LIBRARY_SUFFIX}")
		elseif(MINGW)
			set(CURL_BUNDLED_LIBRARY optimized "${binary_dir}/lib/libcurl${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${binary_dir}/lib/libcurl-d${CMAKE_STATIC_LIBRARY_SUFFIX}")
		else(VSTUDIO)
			set(CURL_BUNDLED_LIBRARY "${binary_dir}/libcurl${CMAKE_STATIC_LIBRARY_SUFFIX}")
		endif(VSTUDIO)

		set(CURL_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/curl/include")

		set_target_properties(bundled_curl PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
	endif()

	#-----------------------------------------------------------------
	# Build bundled Lua library
	#-----------------------------------------------------------------
	if(BUNDLED_LUA AND BUILD_MOD)
		set(LUA_LIB "${CMAKE_CURRENT_LIST_DIR}/lua/src")
		FILE(GLOB LUA_LIB_SRC
			${LUA_LIB}/*.c
		)

		FILE(GLOB LUA_LIB_HEADERS
			${LUA_LIB}/*.h
		)

		add_library(bundled_lua STATIC ${LUA_LIB_SRC} ${LUA_LIB_HEADERS})

		set_target_properties(bundled_lua PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
		set(LUA_BUNDLED_LIBRARIES bundled_lua)
		set(LUA_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/lua/src")
	endif()

	#-----------------------------------------------------------------
	# Build bundled OGG and Vorbis file library
	#-----------------------------------------------------------------
	if(BUNDLED_OGG_VORBIS AND BUILD_CLIENT)
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

		set_target_properties(bundled_ogg PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
		set_target_properties(bundled_ogg_vorbis PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
		set_target_properties(bundled_ogg_vorbis_file PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})

		set(OGG_BUNDLED_LIBRARIES bundled_ogg)
		set(OGG_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/ogg/include")
		set(OGG_VORBIS_BUNDLED_LIBRARIES bundled_ogg_vorbis bundled_ogg_vorbis_file)
		set(OGG_VORBIS_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/vorbis/include")
	endif()

	#-----------------------------------------------------------------
	# Build bundled OpenAL library
	#-----------------------------------------------------------------
	if(BUNDLED_OPENAL AND BUILD_CLIENT)
		ExternalProject_Add(bundled_openal
			SOURCE_DIR	${CMAKE_CURRENT_LIST_DIR}/openal
			BINARY_DIR	${LIBS_BINARYDIR_DIR}/openal
			CMAKE_ARGS	-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
			-DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG} -DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}
			-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS} -DCMAKE_INSTALL_PREFIX=${PROJECT_BINARY_DIR}/openal
			-DLIBTYPE=STATIC -DFORCE_STATIC_VCRT=1 -DALSOFT_UTILS=0 -DALSOFT_NO_CONFIG_UTIL=1
			-DALSOFT_EXAMPLES=0 -DALSOFT_TESTS=0 -DALSOFT_CONFIG=0 -DALSOFT_HRTF_DEFS=0
			INSTALL_COMMAND  ""
		)

		ExternalProject_Get_Property(bundled_openal binary_dir)

		if(VSTUDIO)
			set(OPENAL_BUNDLED_LIBRARIES optimized "${binary_dir}/Release/OpenAL32${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${binary_dir}/Debug/OpenAL32${CMAKE_STATIC_LIBRARY_SUFFIX}")
		elseif(NMAKE_BUILD)
			set(OPENAL_BUNDLED_LIBRARIES "${binary_dir}/OpenAL32${CMAKE_STATIC_LIBRARY_SUFFIX}")
		else(VSTUDIO)
			set(OPENAL_BUNDLED_LIBRARIES "${binary_dir}/libOpenAL32${CMAKE_STATIC_LIBRARY_SUFFIX}")
		endif(VSTUDIO)
		set(OPENAL_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/openal/include")
		set_target_properties(bundled_openal PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
	endif()

elseif(UNIX)

	if(CROSS_COMPILE32)
		if(APPLE)
			set(CROSS_COMPILE32_FLAGS CFLAGS=-mmacosx-version-min=10.7\ -O3\ -m32 LDFLAGS=-mmacosx-version-min=10.7\ -m32)
		else()
			set(CROSS_COMPILE32_FLAGS CFLAGS=-m32 LDFLAGS=-m32)
		endif()
	else(CROSS_COMPILE32)
		# when we don't cross compile we have to enable position independant code '-fPIC' for all bundled libs
		# see http://stackoverflow.com/questions/7216244/why-is-fpic-absolutely-necessary-on-64-and-not-on-32bit-platforms
		# let's misuse CROSS_COMPILE32_FLAGS var (for 64bit) to set our flag. FIXME: rename to CROSS_COMPILE_OPTIONAL_FLAGS?
		# notes: - cflag -mcmodel=large might be an option too
		#        - this has to be done in all dependant CMakeLists-txt files see glew/CMakeLists.txt
		if(APPLE)
			set(CROSS_COMPILE32_FLAGS CFLAGS=-mmacosx-version-min=10.7\ -O3\ -fPIC LDFLAGS=-mmacosx-version-min=10.7)
		else()
			set(CROSS_COMPILE32_FLAGS "CFLAGS=-fPIC")
		endif()
	endif(CROSS_COMPILE32)

	#-----------------------------------------------------------------
	# Build bundled cURL library
	#-----------------------------------------------------------------
	if(BUNDLED_CURL AND (BUILD_CLIENT OR BUILD_SERVER))

		ExternalProject_Add(
			bundled_curl
			SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}/curl
			CONFIGURE_COMMAND ./configure --prefix=${CMAKE_CURRENT_BINARY_DIR}/libs/curl
			--enable-shared=no --enable-static=yes
			--enable-http --enable-ftp --disable-file
			--disable-ldap --disable-ldaps --disable-rtsp
			--enable-proxy --disable-dict --disable-telnet
			--disable-tftp --disable-pop3 --disable-imap
			--disable-smb --disable-smtp --disable-gopher
			--without-ssl --without-libssh2 --without-nghttp2
			--without-gssapi --with-zlib --without-brotli
			--disable-ares --enable-threaded-resolver
			--enable-ipv6 --enable-unix-sockets
			--without-libidn2 --disable-manual
			--disable-sspi --enable-libgcc
			--without-libmetalink --without-libpsl
			--without-librtmp ${CROSS_COMPILE32_FLAGS}
			PREFIX ${CMAKE_CURRENT_BINARY_DIR}/libs/curl
			BUILD_COMMAND make
			INSTALL_COMMAND make install
			BUILD_IN_SOURCE 1
		)

		set(CURL_BUNDLED_LIBRARY "${CMAKE_CURRENT_BINARY_DIR}/libs/curl/lib/libcurl.a")
		set(CURL_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/libs/curl/include")
	endif()

	#-----------------------------------------------------------------
	# Build bundled JPEG library
	#-----------------------------------------------------------------
	if(BUNDLED_JPEG AND BUILD_CLIENT)
		if(CROSS_COMPILE32)
			if(APPLE)
				SET(JPEG_TURBO_BUILD ./configure --with-jpeg8 --build i686-apple-darwin ${CROSS_COMPILE32_FLAGS})
			else()
				SET(JPEG_TURBO_BUILD ./configure --with-jpeg8 --build i686-pc-linux-gnu ${CROSS_COMPILE32_FLAGS})
			endif()
		else(CROSS_COMPILE32)
			if(APPLE)
				SET(JPEG_TURBO_BUILD ./configure --with-jpeg8 --build x86_64-apple-darwin ${CROSS_COMPILE32_FLAGS})
			else()
				SET(JPEG_TURBO_BUILD ./configure --with-jpeg8 ${CROSS_COMPILE32_FLAGS})
			endif()
		endif()

		ExternalProject_Add(
			bundled_jpeg
			SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}/jpegturbo
			PATCH_COMMAND autoreconf -fiv
			CONFIGURE_COMMAND ${JPEG_TURBO_BUILD} --prefix=${CMAKE_CURRENT_BINARY_DIR}/libs/jpegturbo
			PREFIX ${CMAKE_CURRENT_BINARY_DIR}/libs/jpegturbo
			BUILD_COMMAND make
			INSTALL_COMMAND make install
			BUILD_IN_SOURCE 1
		)
		set(JPEG_BUNDLED_LIBRARIES "${CMAKE_CURRENT_BINARY_DIR}/libs/jpegturbo/lib/libturbojpeg.a")
		set(JPEG_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/libs/jpegturbo/include")
	endif()

	#-----------------------------------------------------------------
	# Build bundled Lua library
	#-----------------------------------------------------------------
	# NOTE: the posix32bit target was added into the Lua Makefiles
	if(BUNDLED_LUA AND BUILD_MOD)
		if(CMAKE_SYSTEM MATCHES "OpenBSD*")
			set(LUA_MAKE_TARGET "bsd")
		elseif(CMAKE_SYSTEM MATCHES "Darwin")
			set(LUA_MAKE_TARGET "macosx")
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
	endif()

	#-----------------------------------------------------------------
	# Build bundled OGG and Vorbis file library
	#-----------------------------------------------------------------
	if(BUNDLED_OGG_VORBIS AND BUILD_CLIENT)

		ExternalProject_Add(
			bundled_ogg
			SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}/ogg
			PATCH_COMMAND autoreconf -fiv
			CONFIGURE_COMMAND ./configure --prefix=${CMAKE_CURRENT_BINARY_DIR}/libs/ogg ${CROSS_COMPILE32_FLAGS}
			--enable-silent-rules --disable-dependency-tracking --enable-shared=no
			PREFIX ${CMAKE_CURRENT_BINARY_DIR}/libs/ogg
			BUILD_COMMAND make
			INSTALL_COMMAND make install
			BUILD_IN_SOURCE 1
		)

		set(OGG_BUNDLED_LIBRARIES "${CMAKE_CURRENT_BINARY_DIR}/libs/ogg/lib/libogg.a")
		set(OGG_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/libs/ogg/include")

		# OGG Vorbis File
		set(CFLAGS "${CFLAGS} -I${CMAKE_CURRENT_BINARY_DIR}/libs/ogg/include")
		set(LDFLAGS "${LDFLAGS} -L${CMAKE_CURRENT_BINARY_DIR}/libs/ogg/lib")

		# the above set of CFLAGS and LDFLAGS don't trigger on some systems
		# ensure vorbis configure uses our bundled ogg see --with-ogg-includes & --with-ogg-libraries

		ExternalProject_Add(
			bundled_ogg_vorbis
			DEPENDS bundled_ogg
			SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}/vorbis
			#PATCH_COMMAND ./autogen.sh
			CONFIGURE_COMMAND ./configure --prefix=${CMAKE_CURRENT_BINARY_DIR}/libs/vorbis
			--disable-oggtest --with-ogg-includes=${CMAKE_CURRENT_BINARY_DIR}/libs/ogg/include
			--with-ogg-libraries=${CMAKE_CURRENT_BINARY_DIR}/libs/ogg/lib ${CROSS_COMPILE32_FLAGS}
			--disable-dependency-tracking --enable-silent-rules --enable-shared=no
			PREFIX ${CMAKE_CURRENT_BINARY_DIR}/libs/vorbis
			BUILD_COMMAND make
			INSTALL_COMMAND make install
			BUILD_IN_SOURCE 1
		)
		add_custom_target(bundled_ogg_vorbis_file)
		set(OGG_VORBIS_BUNDLED_LIBRARIES "${CMAKE_CURRENT_BINARY_DIR}/libs/vorbis/lib/libvorbisfile.a" "${CMAKE_CURRENT_BINARY_DIR}/libs/vorbis/lib/libvorbis.a")
		set(OGG_VORBIS_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/libs/vorbis/include")
	endif()

	#-----------------------------------------------------------------
	# Build bundled OpenAL library
	#-----------------------------------------------------------------
	if(BUNDLED_OPENAL AND BUILD_CLIENT)
		ExternalProject_Add(bundled_openal
			SOURCE_DIR	${CMAKE_CURRENT_LIST_DIR}/openal
			BINARY_DIR	${LIBS_BINARYDIR_DIR}/openal
			CMAKE_ARGS	-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
			-DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG} -DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}
			-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS} -DCMAKE_INSTALL_PREFIX=${PROJECT_BINARY_DIR}/openal
			-DCMAKE_OSX_DEPLOYMENT_TARGET="10.7" -DLIBTYPE=STATIC
			-DALSOFT_UTILS=0 -DALSOFT_NO_CONFIG_UTIL=1 -DALSOFT_EXAMPLES=0 -DALSOFT_TESTS=0
			-DALSOFT_CONFIG=0 -DALSOFT_HRTF_DEFS=0
			INSTALL_COMMAND  ""
		)

		ExternalProject_Get_Property(bundled_openal binary_dir)

		set(OPENAL_BUNDLED_LIBRARIES "${binary_dir}/libopenal${CMAKE_STATIC_LIBRARY_SUFFIX}")
		set(OPENAL_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/openal/include")
	elseif(BUNDLED_OPENAL_INCLUDE AND BUILD_CLIENT)
		include_directories(SYSTEM "${CMAKE_CURRENT_LIST_DIR}/openal/include")
	endif()
endif()

#-----------------------------------------------------------------
# Copy bundled SDL library to the etl.exe location
#-----------------------------------------------------------------
if(BUNDLED_SDL AND BUILD_CLIENT)
	# GL render builds (not GLES) for RPI require VIDEO_OPENGLES=1
	if(ARM AND NOT FEATURE_RENDERER_GLES)
		set(SDL_WITH_GLES "ON")
	else()
		set(SDL_WITH_GLES "${FEATURE_RENDERER_GLES}")
	endif()

	# ${CMAKE_CURRENT_BINARY_DIR}/libs/sdl2
	# ${PROJECT_BINARY_DIR}/sdl2
	ExternalProject_Add(bundled_sdl
		SOURCE_DIR	${CMAKE_CURRENT_LIST_DIR}/sdl2
		# DOWNLOAD_DIR ${LIBS_DOWNLOAD_DIR}/sdl2
		# URL https://www.libsdl.org/release/SDL2-2.0.7.tar.gz
		BINARY_DIR	${LIBS_BINARYDIR_DIR}/sdl2
		CMAKE_ARGS	-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS} -DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG}
		-DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE} -DCMAKE_C_FLAGS=${CMAKE_C_FLAGS} -DCMAKE_OSX_DEPLOYMENT_TARGET="10.7"
		-DVIDEO_OPENGLES=${SDL_WITH_GLES} -DSDL_SHARED=OFF -DSDL_RENDER=OFF -DRENDER_D3D=OFF -DFORCE_STATIC_VCRT=ON
		-DCMAKE_INSTALL_PREFIX=${LIBS_BINARYDIR_DIR}/sdl2
		PREFIX ${LIBS_BINARYDIR_DIR}/sdl2
	)

	if(CMAKE_SYSTEM MATCHES "Darwin" OR WIN32)
		set(SDL32_BUNDLED_LIBRARIES optimized "${LIBS_BINARYDIR_DIR}/sdl2/lib/${CMAKE_STATIC_LIBRARY_PREFIX}SDL2main${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${LIBS_BINARYDIR_DIR}/sdl2/lib/${CMAKE_STATIC_LIBRARY_PREFIX}SDL2maind${CMAKE_STATIC_LIBRARY_SUFFIX}")
	endif()
	set(SDL32_BUNDLED_LIBRARIES ${SDL32_BUNDLED_LIBRARIES} optimized "${LIBS_BINARYDIR_DIR}/sdl2/lib/${CMAKE_STATIC_LIBRARY_PREFIX}SDL2${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${LIBS_BINARYDIR_DIR}/sdl2/lib/${CMAKE_STATIC_LIBRARY_PREFIX}SDL2d${CMAKE_STATIC_LIBRARY_SUFFIX}")

	set(SDL32_BUNDLED_INCLUDE_DIR "${LIBS_BINARYDIR_DIR}/sdl2/include")
	set_target_properties(bundled_sdl PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
endif()

#-----------------------------------------------------------------
# Build bundled ZLib library
#-----------------------------------------------------------------
if(BUNDLED_ZLIB AND (BUILD_CLIENT OR BUILD_SERVER))
	set(ZLIB_LIB "${CMAKE_CURRENT_LIST_DIR}/zlib")

	FILE(GLOB ZLIB_LIB_HEADERS
		${ZLIB_LIB}/crc32.h
		${ZLIB_LIB}/gzguts.h
		${ZLIB_LIB}/inffast.h
		${ZLIB_LIB}/inffixed.h
		${ZLIB_LIB}/inflate.h
		${ZLIB_LIB}/inftrees.h
		${ZLIB_LIB}/zconf.h
		${ZLIB_LIB}/zlib.h
		${ZLIB_LIB}/zutil.h
	)

	FILE(GLOB ZLIB_LIB_SRC
		${ZLIB_LIB}/adler32.c
		${ZLIB_LIB}/crc32.c
		${ZLIB_LIB}/inffast.c
		${ZLIB_LIB}/inflate.c
		${ZLIB_LIB}/inftrees.c
		${ZLIB_LIB}/zutil.c
	)

	add_library(bundled_zlib STATIC ${ZLIB_LIB_SRC} ${ZLIB_LIB_HEADERS})
	set(ZLIB_BUNDLED_LIBRARIES bundled_zlib)
	set(ZLIB_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/zlib")
	set_target_properties(bundled_zlib PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
endif()

#-----------------------------------------------------------------
# Build bundled MiniZip library
#-----------------------------------------------------------------
if(BUNDLED_MINIZIP AND (BUILD_CLIENT OR BUILD_SERVER))
	set(MINIZIP_LIB "${CMAKE_CURRENT_LIST_DIR}/minizip")

	FILE(GLOB MINIZIP_LIB_HEADERS
		${MINIZIP_LIB}/crypt.h
		${MINIZIP_LIB}/ioapi.h
		${MINIZIP_LIB}/unzip.h
	)

	FILE(GLOB MINIZIP_LIB_SRC
		${MINIZIP_LIB}/ioapi.c
		${MINIZIP_LIB}/unzip.c
	)

	add_library(bundled_minizip STATIC ${MINIZIP_LIB_SRC} ${MINIZIP_LIB_HEADERS})
	if(BUNDLED_ZLIB)
		target_link_libraries(bundled_minizip bundled_zlib)
	endif(BUNDLED_ZLIB)
	set(MINIZIP_BUNDLED_LIBRARIES bundled_minizip)
	set(MINIZIP_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/minizip")
	set_target_properties(bundled_minizip PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
endif()

#-----------------------------------------------------------------
# Build bundled GLEW library
#-----------------------------------------------------------------
if(BUNDLED_GLEW AND BUILD_CLIENT)
	include(${CMAKE_CURRENT_LIST_DIR}/glew/CMakeLists.txt)
	set(BUNDLED_GLEW_LIBRARIES bundled_glew)
	set(BUNDLED_GLEW_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/glew/include")
	set_target_properties(bundled_glew PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
endif()

#-----------------------------------------------------------------
# Build bundled SQLITE3 library
#-----------------------------------------------------------------
if(BUNDLED_SQLITE3 AND (BUILD_CLIENT OR BUILD_SERVER))
	include(${CMAKE_CURRENT_LIST_DIR}/sqlite3/CMakeLists.txt)
	set(SQLITE3_BUNDLED_LIBRARIES bundled_sqlite3)
	set(SQLITE3_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/sqlite3/src")
	set_target_properties(bundled_sqlite3 PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
endif()

#-----------------------------------------------------------------
# Build bundled Freetype library
#-----------------------------------------------------------------
if(BUNDLED_FREETYPE AND BUILD_CLIENT)

	ExternalProject_Add(bundled_freetype
		SOURCE_DIR	${CMAKE_CURRENT_LIST_DIR}/freetype
		BINARY_DIR	${LIBS_BINARYDIR_DIR}/freetype
		CMAKE_ARGS	-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
		-DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG} -DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}
		-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS} -DCMAKE_OSX_DEPLOYMENT_TARGET="10.7"
		-DCMAKE_DISABLE_FIND_PACKAGE_ZLIB=ON -DCMAKE_DISABLE_FIND_PACKAGE_BZip2=ON -DCMAKE_DISABLE_FIND_PACKAGE_PNG=ON -DCMAKE_DISABLE_FIND_PACKAGE_HarfBuzz=ON
		-DFT_WITH_ZLIB=OFF -DFT_WITH_BZIP2=OFF -DFT_WITH_PNG=OFF -DFT_WITH_HARFBUZZ=OFF  -DDISABLE_FORCE_DEBUG_POSTFIX=ON
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
	set_target_properties(bundled_freetype PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
endif()

#-----------------------------------------------------------------
# Build bundled Theora library
#-----------------------------------------------------------------
if(BUNDLED_THEORA AND BUILD_CLIENT)
	FILE(GLOB THEORA_SRC
		"${CMAKE_CURRENT_LIST_DIR}/theora/lib/*.c"
		"${CMAKE_CURRENT_LIST_DIR}/theora/lib/*.h"
	)

	# This makes the MSVC build a happier camper
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
	set_target_properties(bundled_theora PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
endif()

#-----------------------------------------------------------------
# Build bundled JANSSON library
#-----------------------------------------------------------------
if(BUNDLED_JANSSON AND (BUILD_CLIENT OR BUILD_SERVER))
	ExternalProject_Add(bundled_jansson
		SOURCE_DIR	${CMAKE_CURRENT_LIST_DIR}/jansson
		BINARY_DIR	${LIBS_BINARYDIR_DIR}/jansson
		CMAKE_ARGS	-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
		-DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG} -DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}
		-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS} -DCMAKE_OSX_DEPLOYMENT_TARGET="10.7"
		-DJANSSON_WITHOUT_TESTS=1 -DBUILD_DOCS=0 -DJANSSON_STATIC_CRT=1
		-DJANSSON_BUILD_DOCS=0
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
	set_target_properties(bundled_jansson PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
endif()
