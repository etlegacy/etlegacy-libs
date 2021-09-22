include(ExternalProject)
include(CheckIncludeFile)

set(LIBS_BINARY_DIR ${PROJECT_BINARY_DIR}/libs)
set(LIBS_DOWNLOAD_DIR ${PROJECT_BINARY_DIR}/downloads/pgk)
set(LIBS_DOWNLOAD_SRC_DIR ${PROJECT_BINARY_DIR}/downloads/src)

# note/FIXME/clarify:
# when features are disabled this script is still
# adding the related targets? F.e. LUA_FEATURE is Off and BUNDLED_LUA On
# see usage of BUNDLED_LUA below (BUNDLED_OPENSSL, BUNDLED OPENAL ...)

#CMAKE_DEBUG_POSTFIX

# Force the BUNDLED_<name> to OFF if the FEATURE_<name> is OFF. No more unwanted stuff being built.
get_cmake_property(_variableNames VARIABLES)
list (SORT _variableNames)
foreach (_variableName ${_variableNames})
	string(REGEX MATCH "^FEATURE_.*" _featureName "${_variableName}")
	string(LENGTH "${_featureName}" _variableLen)
	# message(STATUS "${_variableName}=${${_variableName}}")
	if(${_variableLen})
		if(NOT (${_variableName}))
			string(FIND ${_variableName} "_" wsloc)
			string(SUBSTRING ${_variableName} ${wsloc} -1 _featureName)
			string(PREPEND _featureName "BUNDLED")
			if((${_featureName}))
				set(${_featureName} OFF)
			endif()
		endif()
	endif()
endforeach()

if(FEATURE_SSL AND BUNDLED_WOLFSSL)
	find_package(Patch REQUIRED)
	if(Patch_FOUND)
		message("Patch found: ${Patch_EXECUTABLE}")
	endif()

	message(STATUS "Configuring wolfSSL")

	if(VSTUDIO)
		set(WOLFSSL_BUNDLED_LIBRARY optimized "${LIBS_BINARY_DIR}/wolfssl/Release/wolfssl${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${LIBS_BINARY_DIR}/wolfssl/Debug/wolfssl${CMAKE_STATIC_LIBRARY_SUFFIX}")
	elseif(VS_BUILD)
		set(WOLFSSL_BUNDLED_LIBRARY "${LIBS_BINARY_DIR}/wolfssl/lib/wolfssl${CMAKE_STATIC_LIBRARY_SUFFIX}")
	else()
		set(WOLFSSL_BUNDLED_LIBRARY "${LIBS_BINARY_DIR}/wolfssl/lib/libwolfssl${CMAKE_STATIC_LIBRARY_SUFFIX}")
	endif()

	set(WOLFSSL_PATCH_COMMAND "${Patch_EXECUTABLE}" "${LIBS_DOWNLOAD_SRC_DIR}/wolfssl/CMakeLists.txt" "${CMAKE_CURRENT_LIST_DIR}/patches/WolfSSL.patch")

	if(MSVC)
		set(WOLFSSL_FLAGS "${CMAKE_C_FLAGS} /DOPENSSL_ALL=1 /DOPENSSL_EXTRA=1 /DHAVE_OCSP=1 /DHAVE_CRL=1")
	else()
		set(WOLFSSL_FLAGS "${CMAKE_C_FLAGS} -DOPENSSL_ALL=1 -DOPENSSL_EXTRA=1 -DHAVE_OCSP=1 -DHAVE_CRL=1")
	endif()

	ExternalProject_Add(bundled_wolfssl
			DOWNLOAD_DIR ${LIBS_DOWNLOAD_DIR}
			URL https://github.com/wolfSSL/wolfssl/archive/v4.8.1-stable.tar.gz
			URL_HASH MD5=f3b2b4fdfe2ad53fd38bcd2ba6c821d2
			SOURCE_DIR "${LIBS_DOWNLOAD_SRC_DIR}/wolfssl"
			PATCH_COMMAND ${WOLFSSL_PATCH_COMMAND}
			BINARY_DIR ${LIBS_BINARY_DIR}/wolfssl
			BUILD_BYPRODUCTS ${WOLFSSL_BUNDLED_LIBRARY}
			PREFIX ${LIBS_BINARY_DIR}/wolfssl
			CMAKE_ARGS -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
			-DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG} -DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}
			-DCMAKE_C_FLAGS=${WOLFSSL_FLAGS} -DCMAKE_OSX_DEPLOYMENT_TARGET="${CMAKE_OSX_DEPLOYMENT_TARGET}"
			-DWOLFSSL_EXAMPLES=OFF -DWOLFSSL_CRYPT_TESTS=OFF
			-DWOLFSSL_OCSP=ON -DWOLFSSL_OPENSSLEXTRA=ON
			-DWOLFSSL_FAST_MATH=OFF -DWOLFSSL_HARDEN=ON
			-DWOLFSSL_OPENSSLALL=ON -DWOLFSSL_OPENSSL_EXTRA=ON
			-DBUILD_PWDBASED=ON -WOLFSSL_PWDBASED=ON -DBUILD_CRL=ON
			-DCMAKE_INSTALL_PREFIX=${LIBS_BINARY_DIR}/wolfssl
			)
	set(WOLFSSL_BUNDLED_INCLUDE_DIR "${LIBS_BINARY_DIR}/wolfssl/include" "${LIBS_BINARY_DIR}/wolfssl/include/wolfssl")
	set_target_properties(bundled_wolfssl PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
	add_definitions(-DETL_WOLFSSL)
else()
	add_custom_target(bundled_wolfssl)
	set_target_properties(bundled_wolfssl PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
endif()

if(WIN32)

	# moved for now until linux BUNDLED_OPENSSL is done
	if(FEATURE_SSL AND BUNDLED_OPENSSL)
		find_program(NASM_EXECUTABLE nasm)
		if(NOT NASM_EXECUTABLE)
			message(FATAL_ERROR "NASM not found")
		endif()

		# FIXME: there is no findPerl cmake script in project?! (at least for *NIX)
		FIND_PACKAGE(Perl REQUIRED)
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

	if(FEATURE_SSL AND BUNDLED_OPENSSL AND (BUILD_CLIENT OR BUILD_SERVER))
		set(OPENSSL_PREFIX "${LIBS_DOWNLOAD_SRC_DIR}/openssl/build")
		set(OPENSSL_CONFIGURE "${PERL_EXECUTABLE}" Configure "${openssl_plat}" "--prefix=${OPENSSL_PREFIX}" "--openssldir=${OPENSSL_PREFIX}" no-shared no-unit-test -static)
		set(OPENSSL_BUILD nmake)
		set(OPENSSL_INSTALL nmake install_sw)
		set(OPENSSL_BUNDLED_LIBRARY "${OPENSSL_PREFIX}/lib/libcrypto.lib" "${OPENSSL_PREFIX}/lib/libssl.lib")
		ExternalProject_Add(bundled_openssl
			# Use github archive instead of the one hosted on openssl.org because of CMake bug #13251
			#URL_MD5 "76766e98997660138cdaf13a187bd234"
			#GIT_REPOSITORY "https://github.com/openssl/openssl.git"
			DOWNLOAD_DIR ${LIBS_DOWNLOAD_DIR}
			URL https://github.com/openssl/openssl/archive/OpenSSL_1_1_1l.tar.gz
			URL_HASH MD5=2ff02cd10f96671162df3efd60470cfe
			SOURCE_DIR "${LIBS_DOWNLOAD_SRC_DIR}/openssl"
			BUILD_IN_SOURCE 1
			CONFIGURE_COMMAND ${OPENSSL_CONFIGURE}
			BUILD_COMMAND ${OPENSSL_BUILD}
			INSTALL_COMMAND ${OPENSSL_INSTALL}
			BUILD_BYPRODUCTS ${OPENSSL_BUNDLED_LIBRARY}
		)
		set(OPENSSL_BUNDLED_INCLUDE_DIR "${OPENSSL_PREFIX}/include")
		set_target_properties(bundled_openssl PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
	else()
		add_custom_target(bundled_openssl)
		set_target_properties(bundled_openssl PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
	endif()

	#-----------------------------------------------------------------
	# Build bundled cURL library
	#-----------------------------------------------------------------
	if(BUNDLED_CURL AND (BUILD_CLIENT OR BUILD_SERVER))
		set(binary_dir "${LIBS_BINARY_DIR}/curl")
		if(VSTUDIO)
			set(CURL_BUNDLED_LIBRARY optimized "${binary_dir}/lib/Release/libcurl${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${binary_dir}/lib/Debug/libcurl-d${CMAKE_STATIC_LIBRARY_SUFFIX}")
		elseif(MINGW OR VS_BUILD)
			set(CURL_BUNDLED_LIBRARY optimized "${binary_dir}/lib/libcurl${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${binary_dir}/lib/libcurl-d${CMAKE_STATIC_LIBRARY_SUFFIX}")
		else(VSTUDIO)
			set(CURL_BUNDLED_LIBRARY "${binary_dir}/libcurl${CMAKE_STATIC_LIBRARY_SUFFIX}")
		endif(VSTUDIO)

		set(CURL_CMAKE_ARGS
				-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
				-DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG} -DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}
				-DBUILD_CURL_EXE=0 -DBUILD_SHARED_LIBS=0 -DENABLE_ARES=0 -DENABLE_THREADED_RESOLVER=1 -DENABLE_DEBUG=0
				-DENABLE_CURLDEBUG=0 -DBUILD_TESTING=0 -DENABLE_IPV6=1 -DENABLE_MANUAL=0 -DCMAKE_USE_LIBSSH2=0
				-DUSE_NGHTTP2=0 -DCURL_WINDOWS_SSPI=0 -DCURL_ZLIB=AUTO -DCMAKE_USE_GSSAPI=0
				-DCURL_DISABLE_LDAP=1 -DCURL_DISABLE_LDAPS=1 -DCURL_DISABLE_TELNET=1 -DCURL_DISABLE_DICT=1
				-DCURL_DISABLE_FILE=1 -DCURL_DISABLE_TFTP=1 -DCURL_DISABLE_RTSP=1 -DCURL_DISABLE_POP3=1
				-DCURL_DISABLE_IMAP=1 -DCURL_DISABLE_SMTP=1 -DCURL_DISABLE_GOPHER=1 -DENABLE_UNIX_SOCKETS=1
				-DCMAKE_INSTALL_PREFIX=${LIBS_BINARY_DIR}/curl)

		if(MSVC)
			list(APPEND CURL_CMAKE_ARGS -DCURL_STATIC_CRT=1)
		endif()

		if(FEATURE_SSL)
			if(BUNDLED_WOLFSSL)
				include(CheckTypeSize)
				check_type_size("long long" SIZEOF_LONG_LONG)

				list(APPEND CURL_CMAKE_ARGS
						-DCMAKE_C_FLAGS=-DSIZEOF_LONG_LONG=${SIZEOF_LONG_LONG}
						-DCMAKE_USE_OPENSSL=OFF -DCURL_DISABLE_CRYPTO_AUTH=ON
						-DCMAKE_USE_WOLFSSL=ON
						-DCMAKE_LIBRARY_PATH=${LIBS_BINARY_DIR}/wolfssl
						-DWolfSSL_INCLUDE_DIR=${WOLFSSL_BUNDLED_INCLUDE_DIR}
						)
			elseif(BUNDLED_OPENSSL)
				list(APPEND CURL_CMAKE_ARGS -DOPENSSL_ROOT_DIR=${OPENSSL_PREFIX} -DCMAKE_USE_OPENSSL=ON)
			else()
				list(APPEND CURL_CMAKE_ARGS -DCMAKE_USE_OPENSSL=OFF -DCMAKE_USE_SCHANNEL=ON)
			endif()
		else()
			list(APPEND CURL_CMAKE_ARGS -DCMAKE_USE_OPENSSL=OFF)
		endif()

		# -DHTTP_ONLY=1
		ExternalProject_Add(bundled_curl
			DEPENDS bundled_wolfssl bundled_openssl
			DOWNLOAD_DIR ${LIBS_DOWNLOAD_DIR}
			URL https://github.com/curl/curl/archive/curl-7_75_0.tar.gz
			URL_HASH MD5=0afe197dc28d2dbb5cc812776445e280
			SOURCE_DIR "${LIBS_DOWNLOAD_SRC_DIR}/curl"
			# SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR}/curl
			PREFIX ${LIBS_BINARY_DIR}/curl
			BINARY_DIR ${binary_dir}
			BUILD_BYPRODUCTS ${CURL_BUNDLED_LIBRARY}
			CMAKE_ARGS ${CURL_CMAKE_ARGS}
		)

		set(CURL_BUNDLED_INCLUDE_DIR "${LIBS_BINARY_DIR}/curl/include")

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
		set(binary_dir "${LIBS_BINARY_DIR}/openal")
		if(VSTUDIO)
			set(OPENAL_BUNDLED_LIBRARIES optimized "${binary_dir}/Release/OpenAL32${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${binary_dir}/Debug/OpenAL32${CMAKE_STATIC_LIBRARY_SUFFIX}")
		elseif(VS_BUILD)
			set(OPENAL_BUNDLED_LIBRARIES "${binary_dir}/OpenAL32${CMAKE_STATIC_LIBRARY_SUFFIX}")
		else()
			set(OPENAL_BUNDLED_LIBRARIES "${binary_dir}/libOpenAL32${CMAKE_STATIC_LIBRARY_SUFFIX}")
		endif()

		ExternalProject_Add(bundled_openal
			SOURCE_DIR	${CMAKE_CURRENT_LIST_DIR}/openal
			BINARY_DIR	${binary_dir}
			BUILD_BYPRODUCTS ${OPENAL_BUNDLED_LIBRARIES}
			CMAKE_ARGS	-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
			-DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG} -DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}
			-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS} -DCMAKE_INSTALL_PREFIX=${PROJECT_BINARY_DIR}/openal
			-DLIBTYPE=STATIC -DFORCE_STATIC_VCRT=1
			-DALSOFT_UTILS=0 -DALSOFT_NO_CONFIG_UTIL=1 -DALSOFT_EXAMPLES=0 -DALSOFT_TESTS=0
			-DALSOFT_CONFIG=0 -DALSOFT_HRTF_DEFS=0 -DALSOFT_AMBDEC_PRESETS=0
			INSTALL_COMMAND  ""
		)

		#ExternalProject_Get_Property(bundled_openal binary_dir)

		set(OPENAL_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/openal/include")
		set_target_properties(bundled_openal PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
	endif()

elseif(UNIX)

	if(CROSS_COMPILE32)
		if(APPLE)
			set(CROSS_COMPILE32_FLAGS CFLAGS=-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}\ -O3\ -m32 LDFLAGS=-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}\ -m32)
		else()
			set(CROSS_COMPILE32_FLAGS CFLAGS=-m32 LDFLAGS=-m32)
		endif()
	else()
		# when we don't cross compile we have to enable position independant code '-fPIC' for all bundled libs
		# see http://stackoverflow.com/questions/7216244/why-is-fpic-absolutely-necessary-on-64-and-not-on-32bit-platforms
		# let's misuse CROSS_COMPILE32_FLAGS var (for 64bit) to set our flag. FIXME: rename to CROSS_COMPILE_OPTIONAL_FLAGS?
		# notes: - cflag -mcmodel=large might be an option too
		#        - this has to be done in all dependant CMakeLists-txt files see glew/CMakeLists.txt
		if(APPLE)
			set(CROSS_COMPILE32_FLAGS CFLAGS=-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}\ -O3\ -fPIC LDFLAGS=-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET})
		else()
			set(CROSS_COMPILE32_FLAGS "CFLAGS=-fPIC")
		endif()
	endif()

	if (FEATURE_SSL AND BUNDLED_OPENSSL AND (BUILD_CLIENT OR BUILD_SERVER))
		# FIXME: check flags
		if(CROSS_COMPILE32)
			if(APPLE)
				SET(OPENSSL_BUILD ./Configure darwin-i386-cc ${CROSS_COMPILE32_FLAGS})
			else()
				SET(OPENSSL_BUILD ./Configure linux-x86 ${CROSS_COMPILE32_FLAGS})
			endif()
		else()
			if(APPLE)
				SET(OPENSSL_BUILD ./Configure darwin64-x86_64-cc ${CROSS_COMPILE32_FLAGS})
			else()
				#SET(OPENSSL_BUILD ./Configure linux-x86_64 ${CROSS_COMPILE32_FLAGS})
				# better use ./config here?! (..and not the CROSS_COMPILE32_FLAGS?!)
				if(NOT ARM)
					SET(OPENSSL_BUILD ./Configure linux-x86_64)
				else()
					SET(OPENSSL_BUILD ./Configure linux-armv4)
				endif()
			endif()
		endif()

		set(OPENSSL_BUNDLED_LIBRARY "${LIBS_BINARY_DIR}/openssl/lib/libssl.a" "${LIBS_BINARY_DIR}/openssl/lib/libcrypto.a")

		# FIXME:
		# check all the locations of the files (runtime files?!)
		# and enable ssl in CURL
		ExternalProject_Add(
			bundled_openssl
			DOWNLOAD_DIR ${LIBS_DOWNLOAD_DIR}
			URL https://github.com/openssl/openssl/archive/OpenSSL_1_1_1j.tar.gz
			URL_HASH MD5=2913df113ecd2a396a171d9234556ea1
			SOURCE_DIR "${LIBS_DOWNLOAD_SRC_DIR}/openssl"
			CONFIGURE_COMMAND ${OPENSSL_BUILD} --prefix=${CMAKE_CURRENT_BINARY_DIR}/libs/openssl
			--openssldir=${LIBS_BINARY_DIR}/openssl
			PREFIX ${LIBS_BINARY_DIR}/openssl
			BUILD_COMMAND make ${CROSS_COMPILE32_FLAGS}
			INSTALL_COMMAND make install_sw
			BUILD_IN_SOURCE 1
			BUILD_BYPRODUCTS ${OPENSSL_BUNDLED_LIBRARY}
		)

		# also generates libcrypto.a
		set(OPENSSL_BUNDLED_INCLUDE_DIR "${LIBS_BINARY_DIR}/openssl/include")
	else()
		add_custom_target(bundled_openssl)
		set_target_properties(bundled_openssl PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
	endif()

	#-----------------------------------------------------------------
	# Build bundled cURL library
	#-----------------------------------------------------------------
	if(BUNDLED_CURL AND (BUILD_CLIENT OR BUILD_SERVER))

		# FIXME: add openssl lib to project
		# set --with-ssl / remove --without-ssl

		if(APPLE)
			if(CROSS_COMPILE32)
				set(CURL_BUILD_APPEND CFLAGS=-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}\ -O3\ -m32\ -DLUA_USE_MACOSX LDFLAGS=-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}\ -m32)
			else()
				set(CURL_BUILD_APPEND CFLAGS=-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}\ -arch=x86_64\ -pipe\ -Os\ -gdwarf-2\ -fembed-bitcode)
			endif()
		else()
			set(CURL_BUILD_APPEND "")
		endif()

		set(CURL_CONFIGURE autoreconf -iv && ./configure --prefix=${LIBS_BINARY_DIR}/curl
			--enable-shared=no --enable-static=yes
			--enable-http --enable-ftp --disable-file
			--disable-ldap --disable-ldaps --disable-rtsp
			--enable-proxy --disable-dict --disable-telnet
			--disable-tftp --disable-pop3 --disable-imap
			--disable-smb --disable-smtp --disable-gopher
			--without-libssh2 --without-nghttp2 --without-zstd
			--without-gssapi --with-zlib --without-brotli
			--enable-threaded-resolver --disable-sspi
			--enable-ipv6 --without-libidn2
			--without-libmetalink --without-libpsl
			--without-librtmp --disable-manual
		)

		if(APPLE)
			list(APPEND CURL_CONFIGURE --host=x86_64-apple-darwin ${CURL_BUILD_APPEND})
		else()
			list(APPEND CURL_CONFIGURE --enable-unix-sockets --enable-libgcc)
		endif()

		if(FEATURE_SSL)
			if(BUNDLED_WOLFSSL)
				list(APPEND CURL_CONFIGURE --without-ssl --with-wolfssl=${LIBS_BINARY_DIR}/wolfssl)
			elseif(BUNDLED_OPENSSL)
				list(APPEND CURL_CONFIGURE --with-ssl=${LIBS_BINARY_DIR}/openssl)
			else()
				if(APPLE)
					list(APPEND CURL_CONFIGURE --without-ssl --with-secure-transport)
				else()
					list(APPEND CURL_CONFIGURE --with-ssl)
				endif()
			endif()
		else()
			list(APPEND CURL_CONFIGURE --without-ssl)
		endif()

		ExternalProject_Add(
			bundled_curl
			DEPENDS bundled_wolfssl bundled_openssl
			DOWNLOAD_DIR ${LIBS_DOWNLOAD_DIR}
			URL https://github.com/curl/curl/archive/curl-7_79_1.tar.gz
			URL_HASH MD5=7a6ac0611e8fc77aa8b49d6b4bbdbbdc
			SOURCE_DIR "${LIBS_DOWNLOAD_SRC_DIR}/curl"
			CONFIGURE_COMMAND ${CURL_CONFIGURE}
			PREFIX ${CMAKE_CURRENT_BINARY_DIR}/libs/curl
			BUILD_COMMAND make ${CURL_BUILD_APPEND}
			INSTALL_COMMAND make install
			BUILD_IN_SOURCE 1
		)

		set(CURL_BUNDLED_LIBRARY "${CMAKE_CURRENT_BINARY_DIR}/libs/curl/lib/libcurl.a")
		set(CURL_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/libs/curl/include")
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

		# MacOS X requires a different flag order to succeed,
		# but io.popen support requires the initial order
		if(NOT CMAKE_SYSTEM MATCHES "Darwin")
			add_custom_command(OUTPUT ${CMAKE_CURRENT_LIST_DIR}/lua/src/liblua.a
				COMMAND make clean || true
				COMMAND ${CROSS_COMPILE32_FLAGS} make ${LUA_MAKE_TARGET}
				WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/lua/src
			)
		else()
			if(CROSS_COMPILE32)
				set(LUA_BUILD CFLAGS=-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}\ -O3\ -m32\ -DLUA_USE_MACOSX LDFLAGS=-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}\ -m32)
			else()
				set(LUA_BUILD CFLAGS=-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}\ -O3\ -DLUA_USE_MACOSX LDFLAGS=-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET})
			endif()
			add_custom_command(OUTPUT ${CMAKE_CURRENT_LIST_DIR}/lua/src/liblua.a
				COMMAND make clean || true
				COMMAND make ${LUA_MAKE_TARGET} ${LUA_BUILD}
				WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/lua/src
			)
		endif()

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
			BINARY_DIR	${LIBS_BINARY_DIR}/openal
			CMAKE_ARGS	-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
			-DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG} -DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}
			-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS} -DCMAKE_INSTALL_PREFIX=${PROJECT_BINARY_DIR}/openal
			-DCMAKE_OSX_DEPLOYMENT_TARGET="${CMAKE_OSX_DEPLOYMENT_TARGET}" -DLIBTYPE=STATIC
			-DALSOFT_UTILS=0 -DALSOFT_NO_CONFIG_UTIL=1 -DALSOFT_EXAMPLES=0 -DALSOFT_TESTS=0
			-DALSOFT_CONFIG=0 -DALSOFT_HRTF_DEFS=0 -DALSOFT_AMBDEC_PRESETS=0 -DALSOFT_BACKEND_SNDIO=OFF
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
	if(CMAKE_SYSTEM MATCHES "Darwin" OR WIN32)
		set(SDL32_BUNDLED_LIBRARIES optimized "${LIBS_BINARY_DIR}/sdl2/lib/${CMAKE_STATIC_LIBRARY_PREFIX}SDL2main${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${LIBS_BINARY_DIR}/sdl2/lib/${CMAKE_STATIC_LIBRARY_PREFIX}SDL2maind${CMAKE_STATIC_LIBRARY_SUFFIX}")
	endif()
	set(SDL32_BUNDLED_LIBRARIES ${SDL32_BUNDLED_LIBRARIES} optimized "${LIBS_BINARY_DIR}/sdl2/lib/${CMAKE_STATIC_LIBRARY_PREFIX}SDL2${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${LIBS_BINARY_DIR}/sdl2/lib/${CMAKE_STATIC_LIBRARY_PREFIX}SDL2d${CMAKE_STATIC_LIBRARY_SUFFIX}")

	set(SDL_CMAKE_ARGS -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS} -DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG}
			-DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE} -DCMAKE_C_FLAGS=${CMAKE_C_FLAGS} -DCMAKE_OSX_DEPLOYMENT_TARGET="${CMAKE_OSX_DEPLOYMENT_TARGET}"
			-DRENDER_D3D=OFF -DSDL_RENDER=OFF
			-DVIDEO_DUMMY=OFF -DVIDEO_OPENGL=ON -DVIDEO_VULKAN=OFF
			-DVIDEO_KMSDRM=OFF -DVIDEO_X11_XINPUT=OFF
			-DSDL_SHARED=OFF -DSNDIO=OFF -DHAVE_LIBC=ON
			-DCMAKE_INSTALL_PREFIX=${LIBS_BINARY_DIR}/sdl2)

	# Bye bye X11
	if(APPLE)
		set(SDL_CMAKE_ARGS ${SDL_CMAKE_ARGS} -DVIDEO_X11=OFF -DVIDEO_WAYLAND=OFF -DVIDEO_OPENGLES=OFF -DVIDEO_METAL=OFF -DVIDEO_COCOA=ON)
	elseif(LINUX OR ARM)
		# Wayland requires OpenglES support so that's why its enabled here.
		set(SDL_CMAKE_ARGS ${SDL_CMAKE_ARGS} -DVIDEO_X11=ON -DVIDEO_WAYLAND=ON -DVIDEO_OPENGLES=ON)
	elseif(WIN32)
		set(SDL_CMAKE_ARGS ${SDL_CMAKE_ARGS} -DVIDEO_OPENGLES=${FEATURE_RENDERER_GLES} -DFORCE_STATIC_VCRT=ON)
	endif()

	ExternalProject_Add(bundled_sdl
		# SOURCE_DIR	${CMAKE_CURRENT_LIST_DIR}/sdl2
		DOWNLOAD_DIR ${LIBS_DOWNLOAD_DIR}
		SOURCE_DIR "${LIBS_DOWNLOAD_SRC_DIR}/sdl2"
		URL https://github.com/libsdl-org/SDL/archive/release-2.0.16.tar.gz
		URL_HASH MD5=b52877e5e92d80a20a4be4c868aa1f18
		BINARY_DIR	${LIBS_BINARY_DIR}/sdl2
		BUILD_BYPRODUCTS ${SDL32_BUNDLED_LIBRARIES}
		CMAKE_ARGS ${SDL_CMAKE_ARGS}
		PREFIX ${LIBS_BINARY_DIR}/sdl2
	)

	#ExternalProject_Get_Property(bundled_sdl binary_dir)

	set(SDL32_BUNDLED_INCLUDE_DIR "${LIBS_BINARY_DIR}/sdl2/include")
	set_target_properties(bundled_sdl PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
endif()

#-----------------------------------------------------------------
# Build bundled ZLib library
#-----------------------------------------------------------------
if(BUNDLED_ZLIB AND (BUILD_CLIENT OR BUILD_SERVER))
	set(ZLIB_LIB "${CMAKE_CURRENT_LIST_DIR}/zlib")

	FILE(GLOB ZLIB_LIB_HEADERS
		${ZLIB_LIB}/crc32.h
		${ZLIB_LIB}/deflate.h
		${ZLIB_LIB}/gzguts.h
		${ZLIB_LIB}/inffast.h
		${ZLIB_LIB}/inffixed.h
		${ZLIB_LIB}/inflate.h
		${ZLIB_LIB}/inftrees.h
		${ZLIB_LIB}/trees.h
		${ZLIB_LIB}/zconf.h
		${ZLIB_LIB}/zlib.h
		${ZLIB_LIB}/zutil.h
	)

	FILE(GLOB ZLIB_LIB_SRC
		${ZLIB_LIB}/adler32.c
		${ZLIB_LIB}/compress.c
		${ZLIB_LIB}/crc32.c
		${ZLIB_LIB}/deflate.c
		${ZLIB_LIB}/inffast.c
		${ZLIB_LIB}/inflate.c
		${ZLIB_LIB}/inftrees.c
		${ZLIB_LIB}/trees.c
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
if(BUNDLED_SQLITE3 AND (BUILD_CLIENT OR BUILD_SERVER OR BUILD_MOD))
	include(${CMAKE_CURRENT_LIST_DIR}/sqlite3/CMakeLists.txt)
	set(SQLITE3_BUNDLED_LIBRARIES bundled_sqlite3)
	set(SQLITE3_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/sqlite3/src")
	set_target_properties(bundled_sqlite3 PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
endif()

#-----------------------------------------------------------------
# Build bundled JPEG library
#-----------------------------------------------------------------
if(BUNDLED_JPEG AND BUILD_CLIENT)
	check_include_file(stddef.h HAVE_STDDEF_H)
	check_include_file(stdlib.h HAVE_STDLIB_H)

	set(binary_dir "${LIBS_BINARY_DIR}/jpegturbo")
	if(VSTUDIO)
		set(JPEG_BUNDLED_LIBRARIES optimized "${binary_dir}/Release/turbojpeg-static${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${binary_dir}/Debug/turbojpeg-static${CMAKE_STATIC_LIBRARY_SUFFIX}")
	elseif(VS_BUILD)
		set(JPEG_BUNDLED_LIBRARIES "${binary_dir}/turbojpeg-static${CMAKE_STATIC_LIBRARY_SUFFIX}")
	else()
		set(JPEG_BUNDLED_LIBRARIES "${binary_dir}/libturbojpeg${CMAKE_STATIC_LIBRARY_SUFFIX}")
	endif()

	# Set SIZEOF_SIZE_T  @SIZE_T@ for 64 or 32 bit
	if(CMAKE_SIZEOF_VOID_P EQUAL 8 AND NOT CROSS_COMPILE32)
		set(SIZEOF_SIZE_T 8)
	else()
		set(SIZEOF_SIZE_T 4)
	endif()

	set(JPEG_LIB "${CMAKE_CURRENT_LIST_DIR}/jpegturbo")

	configure_file(${JPEG_LIB}/jconfig.h.cmake ${JPEG_LIB}/jconfig.h)
	configure_file(${JPEG_LIB}/jconfigint.h.cmake ${JPEG_LIB}/jconfigint.h)

	ExternalProject_Add(bundled_jpeg
		SOURCE_DIR	${CMAKE_CURRENT_LIST_DIR}/jpegturbo
		BINARY_DIR	${LIBS_BINARY_DIR}/jpegturbo
		BUILD_BYPRODUCTS ${JPEG_BUNDLED_LIBRARIES}
		CMAKE_ARGS	-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
		-DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG} -DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}
		-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS} -DENABLE_SHARED=OFF -DENABLE_STATIC=ON -DREQUIRE_SIMD=OFF -DWITH_12BIT=OFF
		-DWITH_ARITH_DEC=ON -DWITH_ARITH_ENC=ON -DWITH_JAVA=OFF -DWITH_JPEG7=OFF -DWITH_JPEG8=ON
		-DWITH_MEM_SRCDST=ON -DWITH_SIMD=OFF -DWITH_TURBOJPEG=ON
		-DCMAKE_OSX_DEPLOYMENT_TARGET="${CMAKE_OSX_DEPLOYMENT_TARGET}"
		INSTALL_COMMAND  ""
	)

	#ExternalProject_Get_Property(bundled_jpeg binary_dir)

	set(JPEG_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/jpegturbo")
	set_target_properties(bundled_jpeg PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
endif()

#-----------------------------------------------------------------
# Build bundled PNG library
#-----------------------------------------------------------------
if(BUNDLED_PNG AND BUILD_CLIENT)
	set(binary_dir "${LIBS_BINARY_DIR}/libpng")
	if(VSTUDIO)
		set(PNG_BUNDLED_LIBRARIES optimized "${binary_dir}/Release/libpng${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${binary_dir}/Debug/libpng${CMAKE_STATIC_LIBRARY_SUFFIX}")
	elseif(VS_BUILD)
		set(PNG_BUNDLED_LIBRARIES "${binary_dir}/libpng${CMAKE_STATIC_LIBRARY_SUFFIX}")
	else()
		set(PNG_BUNDLED_LIBRARIES "${binary_dir}/libpng${CMAKE_STATIC_LIBRARY_SUFFIX}")
	endif()

	if(BUNDLED_ZLIB)
		set(ZLIB_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/zlib")
	endif()

	ExternalProject_Add(bundled_png
		SOURCE_DIR	${CMAKE_CURRENT_LIST_DIR}/libpng
		BINARY_DIR	${LIBS_BINARY_DIR}/libpng
		BUILD_BYPRODUCTS ${PNG_BUNDLED_LIBRARIES}
		CMAKE_ARGS	-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
		-DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG} -DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}
		-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS} -DPNG_SHARED=OFF -DPNG_STATIC=ON -DPNG_BUILD_ZLIB=ON -DZLIB_INCLUDE_DIR=${ZLIB_INCLUDE_DIR}
		-DPNG_TESTS=OFF -DPNG_FRAMEWORK=OFF -DPNG_DEBUG=OFF -DPNG_HARDWARE_OPTIMIZATIONS=ON
		INSTALL_COMMAND  ""
	)

	#ExternalProject_Get_Property(bundled_png binary_dir)

	set(PNG_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/libpng/include")
	set_target_properties(bundled_png PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
endif()

#-----------------------------------------------------------------
# Build bundled Freetype library
#-----------------------------------------------------------------
if(BUNDLED_FREETYPE AND BUILD_CLIENT)
	set(binary_dir "${LIBS_BINARY_DIR}/freetype")
	if(VSTUDIO)
		set(BUNDLED_FREETYPE_LIBRARIES optimized "${binary_dir}/Release/freetype${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${binary_dir}/Debug/freetype${CMAKE_STATIC_LIBRARY_SUFFIX}")
	elseif(VS_BUILD)
		set(BUNDLED_FREETYPE_LIBRARIES "${binary_dir}/freetype${CMAKE_STATIC_LIBRARY_SUFFIX}")
	else()
		set(BUNDLED_FREETYPE_LIBRARIES "${binary_dir}/libfreetype${CMAKE_STATIC_LIBRARY_SUFFIX}")
	endif()

	ExternalProject_Add(bundled_freetype
		SOURCE_DIR	${CMAKE_CURRENT_LIST_DIR}/freetype
		BINARY_DIR	${binary_dir}
		BUILD_BYPRODUCTS ${BUNDLED_FREETYPE_LIBRARIES}
		CMAKE_ARGS	-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
		-DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG} -DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}
		-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS} -DCMAKE_OSX_DEPLOYMENT_TARGET="${CMAKE_OSX_DEPLOYMENT_TARGET}"
		-DCMAKE_DISABLE_FIND_PACKAGE_ZLIB=ON -DCMAKE_DISABLE_FIND_PACKAGE_BZip2=ON -DCMAKE_DISABLE_FIND_PACKAGE_PNG=ON
		-DCMAKE_DISABLE_FIND_PACKAGE_HarfBuzz=ON -DCMAKE_DISABLE_FIND_PACKAGE_BrotliDec=ON
		-DFT_WITH_ZLIB=OFF -DFT_WITH_BZIP2=OFF -DFT_WITH_PNG=OFF -DFT_WITH_HARFBUZZ=OFF -DFT_WITH_BROTLI=OFF -DDISABLE_FORCE_DEBUG_POSTFIX=ON
		INSTALL_COMMAND  ""
	)

	# ExternalProject_Get_Property(bundled_freetype binary_dir)

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

	set(THEORA_BUNDLED_LIBRARIES bundled_theora)
	set(THEORA_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/theora/include")
	set_target_properties(bundled_theora PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
endif()
