include(ExternalProject)
include(CheckIncludeFile)

set(LIBS_BINARY_DIR ${PROJECT_BINARY_DIR}/libs)
set(LIBS_DOWNLOAD_DIR ${PROJECT_BINARY_DIR}/downloads/pgk)
set(LIBS_DOWNLOAD_SRC_DIR ${PROJECT_BINARY_DIR}/downloads/src)

# keep this check in sync with the external libs build commands
if (UNIX AND (BUNDLED_OGG_VORBIS OR BUNDLED_OPENSSL OR BUNDLED_LUA))
	find_program(MAKE NAMES make gmake mingw32-make REQUIRED)
endif()

# note/FIXME/clarify:
# when features are disabled this script is still
# adding the related targets? F.e. LUA_FEATURE is Off and BUNDLED_LUA On
# see usage of BUNDLED_LUA below (BUNDLED_OPENSSL, BUNDLED OPENAL ...)

#CMAKE_DEBUG_POSTFIX

if (APPLE)
	# The list values need to escaped for the external projects (if we have more than one architecture set)
	string(REPLACE ";" "$<SEMICOLON>" CMAKE_OSX_ARCHITECTURES_ "${CMAKE_OSX_ARCHITECTURES}")
endif()

if (ANDROID)
	get_property(dirs DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY INCLUDE_DIRECTORIES)
	foreach(dir ${dirs})
		message(INFO "Adding include dir='${dir}'")
		list(APPEND CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES ${dir})
		list(APPEND CMAKE_C_STANDARD_INCLUDE_DIRECTORIES ${dir})
	endforeach()
endif()

if (CMAKE_INSTALL_LIBDIR)
	set(LIBS_LIB_DIR ${CMAKE_INSTALL_LIBDIR})
else()
	set(LIBS_LIB_DIR lib)
endif()

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

# a possible list of libraries that have "optimized" and "debug" between them
# returns the library that matches the requested build profile
function(etl_find_lib_path list _out)
	if(DEBUG_BUILD)
		set(_what "debug")
	else()
		set(_what "optimized")
	endif()

	list(FIND ${list} "${_what}" _find_index)
	if ("${_find_index}" EQUAL "-1")
		set(${_out} ${${list}} PARENT_SCOPE)
		return()
	endif()

	math(EXPR _find_index "${_find_index}+1")
	list(GET ${list} ${_find_index} _found_item)

	list(APPEND TMP_OUT ${_found_item})

	list(LENGTH ${list} _LIST_LEN)
	math(EXPR _find_index "${_find_index}+1")

	if (_find_index GREATER_EQUAL _LIST_LEN)
		set(${_out} ${TMP_OUT} PARENT_SCOPE)
		return()
	endif()

	list(SUBLIST ${list} 0 -1 _SUBLIST)
	list(SUBLIST ${list} ${_find_index} -1 _SUBLIST)

	while(true)
		list(FIND _SUBLIST "${_what}" _find_index)
		if ("${_find_index}" EQUAL "-1")
			set(${_out} ${TMP_OUT} PARENT_SCOPE)
			return()
		endif()

		math(EXPR _find_index "${_find_index}+1")
		list(GET _SUBLIST ${_find_index} _found_item)

		list(APPEND TMP_OUT ${_found_item})

		list(LENGTH _SUBLIST _LIST_LEN)
		math(EXPR _find_index "${_find_index}+1")

		if (_find_index GREATER_EQUAL _LIST_LEN)
			set(${_out} ${TMP_OUT} PARENT_SCOPE)
			return()
		endif()

		list(SUBLIST _SUBLIST ${_find_index} -1 _SUBLIST)
	endwhile()
endfunction()

# ensure that all the required flags get passed to the sub-projects
# these include the msvc runtime, apple architectures and android toolchain flags
function(etl_setup_cmake_args _list)
	if (NOT ${_list})
		set(${_list} "" PARENT_SCOPE)
	endif()
	list(APPEND ${_list} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS}
			-DCMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG} -DCMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}
			-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS} -DCMAKE_C_FLAGS_DEBUG=${CMAKE_C_FLAGS_DEBUG} -DCMAKE_C_FLAGS_RELEASE=${CMAKE_C_FLAGS_RELEASE})

	if (CMAKE_C_STANDARD_INCLUDE_DIRECTORIES)
		list(APPEND ${_list} -DCMAKE_C_STANDARD_INCLUDE_DIRECTORIES=${CMAKE_C_STANDARD_INCLUDE_DIRECTORIES})
	endif()

	if (CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES)
		list(APPEND ${_list} -DCMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES=${CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES})
	endif()

	if (APPLE)
		list(APPEND ${_list} -DCMAKE_OSX_DEPLOYMENT_TARGET="${CMAKE_OSX_DEPLOYMENT_TARGET}"
				-DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES_})
	endif()

	if (MSVC)
		list(APPEND ${_list} -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded$<$<CONFIG:Debug>:Debug>)
	endif()

	# NOTE: set the CMAKE_POSITION_INDEPENDENT_CODE flag for all bundled libs (-fPIC) on 64 bit
	if (ETL_64BITS)
		list(APPEND ${_list} -DCMAKE_POSITION_INDEPENDENT_CODE=ON)
	endif()

	# Stuff that configures the Android toolchain file (needs to be kept up to date)
	if (ANDROID)
		if (ANDROID_TOOLCHAIN)
			list(APPEND ${_list} -DANDROID_TOOLCHAIN=${ANDROID_TOOLCHAIN})
		endif()

		if (ANDROID_ABI)
			list(APPEND ${_list} -DANDROID_ABI=${ANDROID_ABI})
		endif()

		if (ANDROID_PLATFORM)
			list(APPEND ${_list} -DANDROID_PLATFORM=${ANDROID_PLATFORM})
		endif()

		if (ANDROID_STL)
			list(APPEND ${_list} -DANDROID_STL=${ANDROID_STL})
		endif()

		if (ANDROID_PIE)
			list(APPEND ${_list} -DANDROID_PIE=${ANDROID_PIE})
		endif()

		if (ANDROID_CPP_FEATURES)
			list(APPEND ${_list} -DANDROID_CPP_FEATURES=${ANDROID_CPP_FEATURES})
		endif()

		if (ANDROID_ALLOW_UNDEFINED_SYMBOLS)
			list(APPEND ${_list} -DANDROID_ALLOW_UNDEFINED_SYMBOLS=${ANDROID_ALLOW_UNDEFINED_SYMBOLS})
		endif()

		if (ANDROID_ARM_MODE)
			list(APPEND ${_list} -DANDROID_ARM_MODE=${ANDROID_ARM_MODE})
		endif()

		if (ANDROID_DISABLE_FORMAT_STRING_CHECKS)
			list(APPEND ${_list} -DANDROID_DISABLE_FORMAT_STRING_CHECKS=${ANDROID_DISABLE_FORMAT_STRING_CHECKS})
		endif()

		if (ANDROID_CCACHE)
			list(APPEND ${_list} -DANDROID_CCACHE=${ANDROID_CCACHE})
		endif()
	endif()

	# Make sure the make program is also passed to the sub-projects (if set)
	if (CMAKE_MAKE_PROGRAM)
		list(APPEND ${_list} -DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM})
	endif()

	if (CMAKE_TOOLCHAIN_FILE)
		list(APPEND ${_list} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE})
	endif()

	if (CMAKE_POLICY_VERSION_MINIMUM)
		list(APPEND ${_list} -DCMAKE_POLICY_VERSION_MINIMUM=${CMAKE_POLICY_VERSION_MINIMUM})
	endif()

	if (NOT "${ARGN}" MATCHES "-DCMAKE_INSTALL_PREFIX=")
		message(VERBOSE "Appending default install prefix to the cmake args")
		list(APPEND ${_list} -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>)
	endif()

	if (NOT "${ARGN}" MATCHES "-DCMAKE_INSTALL_LIBDIR=" AND UNIX)
		message(VERBOSE "Appending default 32 bit gnu libdir to the cmake args")
		list(APPEND ${_list} -DCMAKE_INSTALL_LIBDIR=<INSTALL_DIR>/lib)
	endif()

	if (ARGC GREATER 1)
		list(APPEND ${_list} ${ARGN})
	endif()
	set(${_list} ${${_list}} PARENT_SCOPE)
endfunction()

if(UNIX)
	if(CROSS_COMPILE32)
		if(APPLE)
			set(LIBS_COMPILE_FLAGS CFLAGS=-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}\ -O3\ -m32 LDFLAGS=-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}\ -m32)
		else()
			set(LIBS_COMPILE_FLAGS CFLAGS=-m32 LDFLAGS=-m32)
		endif()
	else()
		# when we don't cross compile we have to enable position independent code '-fPIC' for all bundled libs
		# see http://stackoverflow.com/questions/7216244/why-is-fpic-absolutely-necessary-on-64-and-not-on-32bit-platforms
		# let's misuse LIBS_COMPILE_FLAGS var (for 64bit) to set our flag.
		# notes: - cflag -mcmodel=large might be an option too
		#		 - this has to be done in all dependant CMakeLists-txt files see glew/CMakeLists.txt
		if(APPLE)
			set(LIBS_COMPILE_FLAGS CFLAGS=-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}\ -O3\ -fPIC LDFLAGS=-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET})
		else()
			set(LIBS_COMPILE_FLAGS "CFLAGS=-fPIC")
		endif()
	endif()
endif()

#-----------------------------------------------------------------
# Build bundled WolfSSL library
#-----------------------------------------------------------------
if(FEATURE_SSL AND BUNDLED_WOLFSSL AND (BUILD_CLIENT OR BUILD_SERVER))
	add_library(bundled_wolfssl_int INTERFACE)

	find_package(Patch REQUIRED)
	if(Patch_FOUND)
		message(STATUS "Patch found: ${Patch_EXECUTABLE}")
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

	#if(MSVC)
	# set(WOLFSSL_FLAGS "${CMAKE_C_FLAGS} /DOPENSSL_ALL=1 /DWOLFSSL_DES_ECB=1 /DHAVE_OCSP=1 /DHAVE_CRL=1")
	#else()
	#	set(WOLFSSL_FLAGS "${CMAKE_C_FLAGS} -DOPENSSL_ALL=1 -DWOLFSSL_DES_ECB=1 -DHAVE_OCSP=1 -DHAVE_CRL=1")
	#endif()

	etl_find_lib_path(WOLFSSL_BUNDLED_LIBRARY _WOLFSSL_OUTPUT)
	etl_setup_cmake_args(wolfssl_cmake_args
			-DWOLFSSL_EXAMPLES=OFF -DWOLFSSL_CRYPT_TESTS=OFF -DWOLFSSL_OCSP=yes
			-DWOLFSSL_OPENSSLEXTRA=yes -DWOLFSSL_FAST_MATH=OFF -DWOLFSSL_HARDEN=yes
			-DWOLFSSL_OPENSSL_EXTRA=yes -DBUILD_PWDBASED=yes -DWOLFSSL_PWDBASED=yes
			-DBUILD_CRL=yes -DWOLFSSL_DES3=yes -DWOLFSSL_TLSX=yes -DWOLFSSL_CHACHA=OFF
			-DBUILD_SHARED_LIBS=OFF -DWOLFSSL_CURL=yes -DWOLFSSL_OPENSSLALL=yes
			-DWOLFSSL_ASIO=yes -DWOLFSSL_CRL=yes
			-DCMAKE_INSTALL_PREFIX=${LIBS_BINARY_DIR}/wolfssl
	)

	ExternalProject_Add(bundled_wolfssl
			DOWNLOAD_DIR ${LIBS_DOWNLOAD_DIR}
			URL https://github.com/wolfSSL/wolfssl/releases/download/v5.6.6-stable/wolfssl-5.6.6.tar.gz
			URL_HASH MD5=772dfa0eed22e31d9d2fb457a1343138
			SOURCE_DIR "${LIBS_DOWNLOAD_SRC_DIR}/wolfssl"
			BINARY_DIR ${LIBS_BINARY_DIR}/wolfssl
			BUILD_BYPRODUCTS ${_WOLFSSL_OUTPUT}
			PREFIX ${LIBS_BINARY_DIR}/wolfssl
			CMAKE_ARGS ${wolfssl_cmake_args}
	)
	set_target_properties(bundled_wolfssl PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})

	add_dependencies(bundled_wolfssl_int bundled_wolfssl)

	target_link_libraries(bundled_wolfssl_int INTERFACE ${WOLFSSL_BUNDLED_LIBRARY})
	target_include_directories(bundled_wolfssl_int INTERFACE "${LIBS_BINARY_DIR}/wolfssl/include" "${LIBS_BINARY_DIR}/wolfssl/include/wolfssl")
	target_compile_definitions(bundled_wolfssl_int INTERFACE ETL_WOLFSSL)
else()
	add_custom_target(bundled_wolfssl)
	set_target_properties(bundled_wolfssl PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
endif()

#-----------------------------------------------------------------
# Build bundled OpenSSL library
#-----------------------------------------------------------------
if (FEATURE_SSL AND BUNDLED_OPENSSL AND (BUILD_CLIENT OR BUILD_SERVER))
	add_library(bundled_openssl_int INTERFACE)

	if (WIN32)
		find_program(NASM_EXECUTABLE nasm)
		if(NOT NASM_EXECUTABLE)
			message(FATAL_ERROR "NASM not found")
		endif()

		# FIXME: there is no findPerl cmake script in project?! (at least for *NIX)
		FIND_PACKAGE(Perl REQUIRED)
		if(NOT PERL_FOUND)
			message(FATAL_ERROR "Perl not found")
		endif()

		if(ETL_64BITS)
			set(openssl_plat VC-WIN64)
			set(openssl_lib_folder lib64)
			# set(curl_plat x64)
		else()
			set(openssl_plat VC-WIN32)
			set(openssl_lib_folder lib)
			# set(curl_plat x86)
		endif()

		set(OPENSSL_PREFIX "${LIBS_DOWNLOAD_SRC_DIR}/openssl/build")
		set(OPENSSL_CONFIGURE "${PERL_EXECUTABLE}" Configure "${openssl_plat}" "--prefix=${OPENSSL_PREFIX}" "--openssldir=${OPENSSL_PREFIX}" no-shared no-unit-test -static)
		set(OPENSSL_BUILD nmake)
		set(OPENSSL_INSTALL nmake install_sw)
		set(OPENSSL_BUNDLED_LIBRARY "${OPENSSL_PREFIX}/${openssl_lib_folder}/libcrypto.lib" "${OPENSSL_PREFIX}/${openssl_lib_folder}/libssl.lib")
		ExternalProject_Add(bundled_openssl
				# Use github archive instead of the one hosted on openssl.org because of CMake bug #13251
				#URL_MD5 "76766e98997660138cdaf13a187bd234"
				#GIT_REPOSITORY "https://github.com/openssl/openssl.git"
				DOWNLOAD_DIR ${LIBS_DOWNLOAD_DIR}
				URL https://github.com/openssl/openssl/releases/download/openssl-3.2.0/openssl-3.2.0.tar.gz
				URL_HASH MD5=7903549a14abebc5c323ce4e85f2cbb2
				SOURCE_DIR "${LIBS_DOWNLOAD_SRC_DIR}/openssl"
				BUILD_IN_SOURCE 1
				CONFIGURE_COMMAND ${OPENSSL_CONFIGURE}
				BUILD_COMMAND ${OPENSSL_BUILD}
				INSTALL_COMMAND ${OPENSSL_INSTALL}
				BUILD_BYPRODUCTS ${OPENSSL_BUNDLED_LIBRARY}
				)
		set(OPENSSL_BUNDLED_INCLUDE_DIR "${OPENSSL_PREFIX}/include")
		set_target_properties(bundled_openssl PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})

		add_dependencies(bundled_openssl_int bundled_openssl)
		target_link_libraries(bundled_openssl_int INTERFACE ${OPENSSL_BUNDLED_LIBRARY})
		target_include_directories(bundled_openssl_int INTERFACE "${OPENSSL_PREFIX}/include")
	elseif (UNIX)

		set(openssl_lib_folder lib)
		set(OPENSSL_PREFIX "${LIBS_BINARY_DIR}/openssl")

		# FIXME: check flags
		if(ETL_32BITS)
			if(APPLE)
				SET(OPENSSL_BUILD ./Configure darwin-i386-cc ${LIBS_COMPILE_FLAGS})
			else()
				SET(OPENSSL_BUILD ./Configure linux-x86 ${LIBS_COMPILE_FLAGS})
			endif()
		else()
			if(ETL_ARM)
				if(APPLE)
					SET(OPENSSL_BUILD ./Configure darwin64-arm64 ${LIBS_COMPILE_FLAGS})
				else()
					SET(OPENSSL_BUILD ./Configure linux-aarch64)
				endif()
			else()
				if(APPLE)
					SET(OPENSSL_BUILD ./Configure darwin64-x86_64 ${LIBS_COMPILE_FLAGS})
				else()
					SET(OPENSSL_BUILD ./Configure linux-x86_64)
				endif()
			endif()
		endif()

		set(OPENSSL_BUNDLED_LIBRARY "${LIBS_BINARY_DIR}/openssl/${openssl_lib_folder}/libssl.a" "${LIBS_BINARY_DIR}/openssl/${openssl_lib_folder}/libcrypto.a")

		if(CMAKE_CROSSCOMPILING AND CMAKE_C_COMPILER_ID STREQUAL "GNU")
				string(REGEX REPLACE "gcc$" "" COMPILER_PREFIX "${CMAKE_C_COMPILER}")
				if(COMPILER_PREFIX)
						SET(OPENSSL_BUILD ${OPENSSL_BUILD} --sysroot=${CMAKE_SYSROOT} --cross-compile-prefix=${COMPILER_PREFIX})
				else()
						SET(OPENSSL_BUILD ${OPENSSL_BUILD} --sysroot=${CMAKE_SYSROOT})
				endif()
		endif()

		# FIXME:
		# check all the locations of the files (runtime files?!)
		# and enable ssl in CURL
		ExternalProject_Add(
				bundled_openssl
				DOWNLOAD_DIR ${LIBS_DOWNLOAD_DIR}
				URL https://github.com/openssl/openssl/releases/download/openssl-3.2.0/openssl-3.2.0.tar.gz
				URL_HASH MD5=7903549a14abebc5c323ce4e85f2cbb2
				PREFIX ${OPENSSL_PREFIX}
				CONFIGURE_COMMAND ${OPENSSL_BUILD} --prefix=<INSTALL_DIR>
				--openssldir=<INSTALL_DIR> --libdir=${openssl_lib_folder}
				BUILD_COMMAND ${MAKE} -j ${LIBS_COMPILE_FLAGS}
				INSTALL_COMMAND ${MAKE} install_sw
				BUILD_IN_SOURCE 1
				BUILD_BYPRODUCTS ${OPENSSL_BUNDLED_LIBRARY}
		)

		# also generates libcrypto.a
		set(OPENSSL_BUNDLED_INCLUDE_DIR "${OPENSSL_PREFIX}/include")

		add_dependencies(bundled_openssl_int bundled_openssl)
		target_link_libraries(bundled_openssl_int INTERFACE ${OPENSSL_BUNDLED_LIBRARY})
		target_include_directories(bundled_openssl_int INTERFACE "${OPENSSL_PREFIX}/include")
	endif()
else()
	add_custom_target(bundled_openssl)
	set_target_properties(bundled_openssl PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
endif()

#-----------------------------------------------------------------
# Build bundled cURL library
#-----------------------------------------------------------------
if(BUNDLED_CURL AND (BUILD_CLIENT OR BUILD_SERVER))
	add_library(bundled_curl_int INTERFACE)

	set(CURL_DOWNLOAD_URL "https://github.com/curl/curl/releases/download/curl-8_5_0/curl-8.5.0.tar.gz")
	set(CURL_DOWNLOAD_HASH "MD5=0bc69288b20ae165ff4b7d6d7bbe70d2")
	etl_setup_cmake_args(CURL_CMAKE_ARGS
			-DBUILD_CURL_EXE=OFF -DBUILD_SHARED_LIBS=OFF -DENABLE_ARES=OFF -DENABLE_THREADED_RESOLVER=ON
			-DENABLE_CURLDEBUG=OFF -DBUILD_TESTING=OFF -DENABLE_IPV6=ON -DENABLE_MANUAL=OFF -DCURL_USE_LIBPSL=OFF
			-DUSE_NGHTTP2=OFF -DCURL_WINDOWS_SSPI=OFF -DCURL_ZLIB=AUTO -DCMAKE_USE_GSSAPI=OFF
			-DUSE_LIBIDN2=OFF -DCURL_USE_LIBSSH=OFF -DCURL_USE_LIBSSH2=OFF -DENABLE_DEBUG=OFF
			-DCURL_DISABLE_LDAP=ON -DCURL_DISABLE_LDAPS=ON -DCURL_DISABLE_TELNET=ON -DCURL_DISABLE_DICT=ON
			-DCURL_DISABLE_FILE=ON -DCURL_DISABLE_TFTP=ON -DCURL_DISABLE_RTSP=ON -DCURL_DISABLE_POP3=ON
			-DCURL_DISABLE_IMAP=ON -DCURL_DISABLE_SMTP=ON -DCURL_DISABLE_GOPHER=ON -DENABLE_UNIX_SOCKETS=ON
	)
	set(binary_dir "${LIBS_BINARY_DIR}/curl")

	if (WIN32)

		if(MINGW OR VS_BUILD OR VSTUDIO)
			set(CURL_BUNDLED_LIBRARIES optimized "${binary_dir}/lib/libcurl${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${binary_dir}/lib/libcurl-d${CMAKE_STATIC_LIBRARY_SUFFIX}")
		else()
			set(CURL_BUNDLED_LIBRARIES "${binary_dir}/libcurl${CMAKE_STATIC_LIBRARY_SUFFIX}")
		endif()

		if(MSVC)
			list(APPEND CURL_CMAKE_ARGS -DCURL_STATIC_CRT=ON)
		endif()

		if(FEATURE_SSL)
			if(BUNDLED_WOLFSSL)
				include(CheckTypeSize)
				check_type_size("long long" SIZEOF_LONG_LONG)

				list(APPEND CURL_CMAKE_ARGS
						-DCMAKE_C_FLAGS=-DSIZEOF_LONG_LONG=${SIZEOF_LONG_LONG}
						-DCURL_USE_OPENSSL=OFF -DCURL_DISABLE_CRYPTO_AUTH=ON
						-DCURL_USE_WOLFSSL=ON
						-DCMAKE_LIBRARY_PATH=${LIBS_BINARY_DIR}/wolfssl/lib
						-DCMAKE_INCLUDE_PATH=${LIBS_BINARY_DIR}/wolfssl/include
				)
			elseif(BUNDLED_OPENSSL)
				list(APPEND CURL_CMAKE_ARGS -DOPENSSL_ROOT_DIR=${OPENSSL_PREFIX} -DCURL_USE_OPENSSL=ON)
			else()
				list(APPEND CURL_CMAKE_ARGS -DCURL_USE_OPENSSL=OFF -DCURL_USE_SCHANNEL=ON)
			endif()
		else()
			list(APPEND CURL_CMAKE_ARGS -DCURL_USE_OPENSSL=OFF)
		endif()

		etl_find_lib_path(CURL_BUNDLED_LIBRARIES _CURL_OUTPUT)

		# -DHTTP_ONLY=ON
		ExternalProject_Add(bundled_curl
				DEPENDS bundled_wolfssl bundled_openssl
				URL ${CURL_DOWNLOAD_URL}
				URL_HASH ${CURL_DOWNLOAD_HASH}
				PREFIX ${LIBS_BINARY_DIR}/curl
				CMAKE_ARGS ${CURL_CMAKE_ARGS}
		)

		set_target_properties(bundled_curl PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})

		add_dependencies(bundled_curl_int bundled_curl)
		target_link_libraries(bundled_curl_int INTERFACE ${CURL_BUNDLED_LIBRARIES})
		if(MINGW) # Mingw requires the bcrypt library
			target_link_libraries(bundled_curl_int INTERFACE bcrypt)
		endif()
		target_include_directories(bundled_curl_int INTERFACE "${LIBS_BINARY_DIR}/curl/include")
	elseif (APPLE)

		if(BUNDLED_WOLFSSL)
			include(CheckTypeSize)
			check_type_size("long long" SIZEOF_LONG_LONG)

			list(APPEND CURL_CMAKE_ARGS
					-DCMAKE_C_FLAGS=-DSIZEOF_LONG_LONG=${SIZEOF_LONG_LONG}
					-DCURL_USE_OPENSSL=OFF -DCURL_DISABLE_CRYPTO_AUTH=ON
					-DCURL_USE_WOLFSSL=ON
					-DCMAKE_LIBRARY_PATH=${LIBS_BINARY_DIR}/wolfssl/lib
					-DCMAKE_INCLUDE_PATH=${LIBS_BINARY_DIR}/wolfssl/include
			)
		elseif(BUNDLED_OPENSSL)
			list(APPEND CURL_CMAKE_ARGS -DOPENSSL_ROOT_DIR=${OPENSSL_PREFIX} -DCURL_USE_OPENSSL=ON)
		else()
			list(APPEND CURL_CMAKE_ARGS -DCURL_USE_OPENSSL=OFF -DCURL_USE_SECTRANSP=ON)
		endif()

		set(CURL_BUNDLED_LIBRARIES optimized "${binary_dir}/lib/libcurl${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${binary_dir}/lib/libcurl-d${CMAKE_STATIC_LIBRARY_SUFFIX}")
		etl_find_lib_path(CURL_BUNDLED_LIBRARIES _CURL_OUTPUT)

		# -DHTTP_ONLY=ON
		ExternalProject_Add(bundled_curl
				DEPENDS bundled_wolfssl bundled_openssl
				URL ${CURL_DOWNLOAD_URL}
				URL_HASH ${CURL_DOWNLOAD_HASH}
				PREFIX ${LIBS_BINARY_DIR}/curl
				BUILD_BYPRODUCTS ${_CURL_OUTPUT}
				CMAKE_ARGS ${CURL_CMAKE_ARGS}
		)

		set_target_properties(bundled_curl PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})

		add_dependencies(bundled_curl_int bundled_curl)
		target_link_libraries(bundled_curl_int INTERFACE ${CURL_BUNDLED_LIBRARIES})
		target_include_directories(bundled_curl_int INTERFACE "${LIBS_BINARY_DIR}/curl/include")
	elseif (UNIX)

		if(FEATURE_SSL)
			if(BUNDLED_WOLFSSL)
				include(CheckTypeSize)
				check_type_size("long long" SIZEOF_LONG_LONG)

				list(APPEND CURL_CMAKE_ARGS
						-DCMAKE_C_FLAGS=-DSIZEOF_LONG_LONG=${SIZEOF_LONG_LONG}
						-DCURL_USE_OPENSSL=OFF -DCURL_DISABLE_CRYPTO_AUTH=ON
						-DCURL_USE_WOLFSSL=ON
						-DCMAKE_LIBRARY_PATH=${LIBS_BINARY_DIR}/wolfssl/lib
						-DCMAKE_INCLUDE_PATH=${LIBS_BINARY_DIR}/wolfssl/include
				)
			elseif(BUNDLED_OPENSSL)
				list(APPEND CURL_CMAKE_ARGS -DOPENSSL_ROOT_DIR=${OPENSSL_PREFIX} -DOPENSSL_USE_STATIC_LIBS=ON -DCURL_USE_OPENSSL=ON -DCURL_USE_WOLFSSL=OFF)
			else()
				message(WARNING "Using system OpenSSL")
				list(APPEND CURL_CMAKE_ARGS -DCURL_USE_OPENSSL=ON -DCURL_USE_WOLFSSL=OFF)
			endif()
		endif()

		set(CURL_BUNDLED_LIBRARIES optimized "${binary_dir}/lib/libcurl${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${binary_dir}/lib/libcurl-d${CMAKE_STATIC_LIBRARY_SUFFIX}")
		etl_find_lib_path(CURL_BUNDLED_LIBRARIES _CURL_OUTPUT)

		ExternalProject_Add(bundled_curl
			DEPENDS bundled_wolfssl bundled_openssl
			URL ${CURL_DOWNLOAD_URL}
			URL_HASH ${CURL_DOWNLOAD_HASH}
			PREFIX ${LIBS_BINARY_DIR}/curl
			BUILD_BYPRODUCTS ${_CURL_OUTPUT}
			CMAKE_ARGS ${CURL_CMAKE_ARGS}
		)

		set_target_properties(bundled_curl PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})

		add_dependencies(bundled_curl_int bundled_curl)
		target_link_libraries(bundled_curl_int INTERFACE ${CURL_BUNDLED_LIBRARIES})
		target_include_directories(bundled_curl_int INTERFACE "${LIBS_BINARY_DIR}/curl/include")
	endif()
endif()

#-----------------------------------------------------------------
# Build bundled OpenAL library
#-----------------------------------------------------------------
if(BUNDLED_OPENAL AND BUILD_CLIENT)
	add_library(bundled_openal_int INTERFACE)
	set(binary_dir "${LIBS_BINARY_DIR}/openal")

	if (WIN32)
		if(MSVC)
			set(OPENAL_BUNDLED_LIBRARIES "${binary_dir}/lib/OpenAL32${CMAKE_STATIC_LIBRARY_SUFFIX}")
		else()
			set(OPENAL_BUNDLED_LIBRARIES "${binary_dir}/lib/libOpenAL32${CMAKE_STATIC_LIBRARY_SUFFIX}")
		endif()

		etl_find_lib_path(OPENAL_BUNDLED_LIBRARIES _OPENAL_OUTPUT)
		etl_setup_cmake_args(BUNDLED_OPENAL_CMAKE_ARGS
				-DCMAKE_C_FLAGS=${CMAKE_C_FLAGS}
				-DLIBTYPE=STATIC -DFORCE_STATIC_VCRT=ON -DALSOFT_UTILS=OFF -DALSOFT_NO_CONFIG_UTIL=ON -DALSOFT_EXAMPLES=OFF
				-DALSOFT_TESTS=OFF -DALSOFT_CONFIG=OFF -DALSOFT_HRTF_DEFS=OFF -DALSOFT_AMBDEC_PRESETS=OFF
		)

		ExternalProject_Add(bundled_openal
				PREFIX ${binary_dir}
				URL ${CMAKE_CURRENT_LIST_DIR}/openal
				BUILD_BYPRODUCTS ${_OPENAL_OUTPUT}
				CMAKE_ARGS ${BUNDLED_OPENAL_CMAKE_ARGS}
		)
		set_target_properties(bundled_openal PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})

		add_dependencies(bundled_openal_int bundled_openal)
		target_link_libraries(bundled_openal_int INTERFACE ${OPENAL_BUNDLED_LIBRARIES})
		target_include_directories(bundled_openal_int INTERFACE "${binary_dir}/include")
		target_compile_definitions(bundled_openal_int INTERFACE AL_LIBTYPE_STATIC)
	elseif(UNIX)
		set(OPENAL_BUNDLED_LIBRARIES "${binary_dir}/lib/libopenal.a")
		etl_setup_cmake_args(BUNDLED_OPENAL_CMAKE_ARGS
				-DLIBTYPE=STATIC -DALSOFT_UTILS=OFF -DALSOFT_NO_CONFIG_UTIL=ON -DALSOFT_EXAMPLES=OFF -DALSOFT_TESTS=OFF
				-DALSOFT_CONFIG=OFF -DALSOFT_HRTF_DEFS=OFF -DALSOFT_AMBDEC_PRESETS=OFF -DALSOFT_BACKEND_SNDIO=OFF
		)
		ExternalProject_Add(bundled_openal
				PREFIX ${binary_dir}
				URL ${CMAKE_CURRENT_LIST_DIR}/openal
				BUILD_BYPRODUCTS ${OPENAL_BUNDLED_LIBRARIES}
				CMAKE_ARGS ${BUNDLED_OPENAL_CMAKE_ARGS}
		)

		add_dependencies(bundled_openal_int bundled_openal)
		target_link_libraries(bundled_openal_int INTERFACE ${OPENAL_BUNDLED_LIBRARIES})
		target_include_directories(bundled_openal_int INTERFACE "${binary_dir}/include")
		target_compile_definitions(bundled_openal_int INTERFACE AL_LIBTYPE_STATIC)
	endif()
elseif(APPLE AND BUILD_CLIENT) # due to OSX missing headers in base install
	target_include_directories(client_libraries INTERFACE "${CMAKE_CURRENT_LIST_DIR}/openal/include")
endif()

#-----------------------------------------------------------------
# Build bundled OGG and Vorbis file library
#-----------------------------------------------------------------
if(BUNDLED_OGG_VORBIS AND BUILD_CLIENT)
	add_library(bundled_ogg_full INTERFACE)

	if (APPLE OR CMAKE_CROSSCOMPILING)
		set(OGG_BUNDLED_LIBRARIES "${LIBS_BINARY_DIR}/ogg/lib/libogg${CMAKE_STATIC_LIBRARY_SUFFIX}")
		etl_setup_cmake_args(BUNDLED_OGG_CMAKE_ARGS)
		ExternalProject_Add(bundled_ogg
				PREFIX ${LIBS_BINARY_DIR}/ogg
				URL	${CMAKE_CURRENT_LIST_DIR}/ogg
				BUILD_BYPRODUCTS ${OGG_BUNDLED_LIBRARIES}
				CMAKE_ARGS	${BUNDLED_OGG_CMAKE_ARGS}
		)

		set(VORBIS_BUNDLED_LIBRARIES "${LIBS_BINARY_DIR}/vorbis/lib/libvorbis${CMAKE_STATIC_LIBRARY_SUFFIX}" "${LIBS_BINARY_DIR}/vorbis/lib/libvorbisfile${CMAKE_STATIC_LIBRARY_SUFFIX}")
		etl_setup_cmake_args(BUNDLED_OGG_VORBIS_CMAKE_ARGS
				-DCMAKE_LIBRARY_PATH=${LIBS_BINARY_DIR}/ogg
				-DOGG_ROOT=${LIBS_BINARY_DIR}/ogg
		)

		ExternalProject_Add(bundled_ogg_vorbis
				DEPENDS bundled_ogg
				PREFIX ${LIBS_BINARY_DIR}/vorbis
				URL	${CMAKE_CURRENT_LIST_DIR}/vorbis
				BUILD_BYPRODUCTS ${VORBIS_BUNDLED_LIBRARIES}
				CMAKE_ARGS	${BUNDLED_OGG_VORBIS_CMAKE_ARGS}
		)

		add_dependencies(bundled_ogg_full bundled_ogg_vorbis)
		target_include_directories(bundled_ogg_full INTERFACE "${LIBS_BINARY_DIR}/vorbis/include")
		target_link_libraries(bundled_ogg_full INTERFACE "${VORBIS_BUNDLED_LIBRARIES}")

		add_dependencies(bundled_ogg_full bundled_ogg)
		target_include_directories(bundled_ogg_full INTERFACE "${LIBS_BINARY_DIR}/ogg/include")
		target_link_libraries(bundled_ogg_full INTERFACE "${OGG_BUNDLED_LIBRARIES}")
	elseif(WIN32)
		# OGG
		set(OPATH "${CMAKE_CURRENT_LIST_DIR}/ogg")

		set(OGG_SRC ${OPATH}/src/bitwise.c ${OPATH}/src/framing.c)
		set(OGG_HEADERS ${OPATH}/include/ogg/ogg.h ${OPATH}/include/ogg/os_types.h)

		if(MSVC)
			#ADD_DEFINITIONS(/D_UNICODE /DUNICODE)
			LIST(APPEND OGG_SRC ${OPATH}/win32/ogg.def)
		endif()

		if("${CMAKE_SYSTEM_NAME}" STREQUAL "Linux")
			# libogg expects configure to be called on linux to
			# generate config_types.h
			list(APPEND OGG_HEADERS ${OPATH}/include/ogg/config_types.h)
			add_custom_command(OUTPUT ${OPATH}/include/ogg/config_types.h
					COMMAND ${OPATH}/configure
					DEPENDS ${OPATH}/include/ogg/ogg.h	# Hopefully if the libogg version changes, so does this file
					# so configure_types.h will be regenerated.
					WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
			)
		endif()

		add_library(bundled_ogg STATIC ${OGG_SRC} ${OGG_HEADERS})
		target_include_directories(bundled_ogg PUBLIC "${OPATH}/include")

		set(VPATH "${CMAKE_CURRENT_LIST_DIR}/vorbis")

		set(VORBIS_SRC
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

		set(VORBIS_HEADERS
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

		set(VORBIS_PUB_HEADERS
				${VPATH}/include/vorbis/codec.h
				${VPATH}/include/vorbis/vorbisenc.h
				${VPATH}/include/vorbis/vorbisfile.h
		)

		IF(MSVC)
			#ADD_DEFINITIONS(/D_UNICODE /DUNICODE)
			list(APPEND VORBIS_SRC ${VPATH}/win32/vorbis.def)
		ENDIF(MSVC)

		add_library(bundled_ogg_vorbis STATIC ${VORBIS_SRC} ${VORBIS_HEADERS} ${VORBIS_PUB_HEADERS})
		target_include_directories(bundled_ogg_vorbis PUBLIC "${VPATH}/include" "${VPATH}/lib")
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

		target_link_libraries(bundled_ogg_full INTERFACE bundled_ogg bundled_ogg_vorbis bundled_ogg_vorbis_file)
	else()
		set(OGG_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/libs/ogg/include")
		set(OGG_BUNDLED_LIBRARIES "${CMAKE_CURRENT_BINARY_DIR}/libs/ogg/lib/libogg.a")
		ExternalProject_Add(
				bundled_ogg
				PREFIX ${LIBS_BINARY_DIR}/ogg
				URL ${CMAKE_CURRENT_LIST_DIR}/ogg
				PATCH_COMMAND autoreconf -fiv
				BUILD_BYPRODUCTS ${OGG_BUNDLED_LIBRARIES}
				CONFIGURE_COMMAND ./configure --prefix=<INSTALL_DIR> ${LIBS_COMPILE_FLAGS}
				--enable-silent-rules --disable-dependency-tracking --enable-shared=no
				BUILD_COMMAND ${MAKE} -j -C <SOURCE_DIR>
				INSTALL_COMMAND ${MAKE} -C <SOURCE_DIR> install
				BUILD_IN_SOURCE 1
		)

		# OGG Vorbis File
		set(CFLAGS "${CFLAGS} -I${CMAKE_CURRENT_BINARY_DIR}/libs/ogg/include")
		set(LDFLAGS "${LDFLAGS} -L${CMAKE_CURRENT_BINARY_DIR}/libs/ogg/lib")

		# the above set of CFLAGS and LDFLAGS don't trigger on some systems
		# ensure vorbis configure uses our bundled ogg see --with-ogg-includes & --with-ogg-libraries

		set(OGG_VORBIS_BUNDLED_LIBRARIES "${CMAKE_CURRENT_BINARY_DIR}/libs/vorbis/lib/libvorbisfile.a" "${CMAKE_CURRENT_BINARY_DIR}/libs/vorbis/lib/libvorbis.a")
		set(OGG_VORBIS_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/libs/vorbis/include")
		ExternalProject_Add(
				bundled_ogg_vorbis
				DEPENDS bundled_ogg
				PREFIX ${LIBS_BINARY_DIR}/vorbis
				URL ${CMAKE_CURRENT_LIST_DIR}/vorbis
				#PATCH_COMMAND ./autogen.sh
				BUILD_BYPRODUCTS ${OGG_VORBIS_BUNDLED_LIBRARIES}
				CONFIGURE_COMMAND ./configure --prefix=<INSTALL_DIR>
				--disable-oggtest --with-ogg-includes=${LIBS_BINARY_DIR}/ogg/include
				--with-ogg-libraries=${LIBS_BINARY_DIR}/ogg/lib ${LIBS_COMPILE_FLAGS}
				--disable-dependency-tracking --enable-silent-rules --enable-shared=no
				BUILD_COMMAND ${MAKE} -j -C <SOURCE_DIR>
				INSTALL_COMMAND ${MAKE} -C <SOURCE_DIR> install
				BUILD_IN_SOURCE 1
		)
		add_custom_target(bundled_ogg_vorbis_file)

		add_dependencies(bundled_ogg_full bundled_ogg_vorbis)
		target_include_directories(bundled_ogg_full INTERFACE "${OGG_VORBIS_BUNDLED_INCLUDE_DIR}")
		target_link_libraries(bundled_ogg_full INTERFACE "${OGG_VORBIS_BUNDLED_LIBRARIES}")

		# linker library ordering requires that ogg comes after the vorbis one's
		add_dependencies(bundled_ogg_full bundled_ogg)
		target_include_directories(bundled_ogg_full INTERFACE ${OGG_BUNDLED_INCLUDE_DIR})
		target_link_libraries(bundled_ogg_full INTERFACE ${OGG_BUNDLED_LIBRARIES})
	endif()
endif()

#-----------------------------------------------------------------
# Build bundled Lua library
#-----------------------------------------------------------------
if(BUNDLED_LUA AND BUILD_MOD)
	add_library(bundled_lua_int INTERFACE)
	target_compile_definitions(bundled_lua_int INTERFACE BUNDLED_LUA)

	if (WIN32 OR APPLE OR CMAKE_CROSSCOMPILING)
		set(LUA_LIB "${CMAKE_CURRENT_LIST_DIR}/lua/src")

		FILE(GLOB LUA_LIB_SRC ${LUA_LIB}/*.c)
		list(REMOVE_ITEM LUA_LIB_SRC "${LUA_LIB}/lua.c")
		list(REMOVE_ITEM LUA_LIB_SRC "${LUA_LIB}/luac.c")

		FILE(GLOB LUA_LIB_HEADERS ${LUA_LIB}/*.h)

		add_library(bundled_lua STATIC ${LUA_LIB_SRC} ${LUA_LIB_HEADERS})
		set_target_properties(bundled_lua PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})

		# In the lua makefiles APPLE and POSIX get LUA_USE_READLINE as well, disabling it here since no input is or should be used in the mod..
		if (APPLE)
			target_compile_definitions(bundled_lua PUBLIC LUA_USE_MACOSX)
		elseif(WIN32)
			# target_compile_definitions(bundled_lua PUBLIC LUA_USE_WINDOWS)
		elseif(CMAKE_SYSTEM MATCHES "OpenBSD*")
			target_compile_definitions(bundled_lua PUBLIC LUA_USE_POSIX)
		else()
			target_compile_definitions(bundled_lua PUBLIC LUA_USE_POSIX PUBLIC LUA_USE_DLOPEN)
		endif()

		set(LUA_BUNDLED_LIBRARIES bundled_lua)
		set(LUA_BUNDLED_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/lua/src")

		add_dependencies(bundled_lua_int bundled_lua)
		target_link_libraries(bundled_lua_int INTERFACE bundled_lua)
		target_include_directories(bundled_lua_int INTERFACE ${LUA_BUNDLED_INCLUDE_DIR})
	else()
		if(CMAKE_SYSTEM MATCHES "OpenBSD*")
			set(LUA_MAKE_TARGET "bsd")
		else()
			if(NOT CROSS_COMPILE32)
				set(LUA_MAKE_TARGET "posix")
			else()
				set(LUA_MAKE_TARGET "posix32bit")
			endif()
		endif()

		set(LUA_BUNDLED_LIBRARIES "${LIBS_BINARY_DIR}/lua/lib/liblua.a")
		set(LUA_BUNDLED_INCLUDE_DIR "${LIBS_BINARY_DIR}/lua/include")

		ExternalProject_Add(
				bundled_lua
				PREFIX "${LIBS_BINARY_DIR}/lua"
				URL "${CMAKE_CURRENT_LIST_DIR}/lua"
				BUILD_BYPRODUCTS ${LUA_BUNDLED_LIBRARIES}
				CONFIGURE_COMMAND ${MAKE} -C <SOURCE_DIR>/src clean
				BUILD_COMMAND ${LIBS_COMPILE_FLAGS} ${MAKE} -C <SOURCE_DIR>/src ${LUA_MAKE_TARGET}
				INSTALL_COMMAND ${MAKE} -C <SOURCE_DIR> "INSTALL_TOP=<INSTALL_DIR>" install
				BUILD_IN_SOURCE 1
		)
		add_dependencies(bundled_lua_int bundled_lua)
		target_link_libraries(bundled_lua_int INTERFACE ${LUA_BUNDLED_LIBRARIES})
		target_include_directories(bundled_lua_int INTERFACE ${LUA_BUNDLED_INCLUDE_DIR})
	endif()
endif()

#-----------------------------------------------------------------
# Copy bundled SDL library to the etl.exe location
#-----------------------------------------------------------------
if(BUNDLED_SDL AND BUILD_CLIENT)
	add_library(bundled_sdl_int INTERFACE)

	if(CMAKE_SYSTEM MATCHES "Darwin" OR WIN32)
		set(SDL2_BUNDLED_LIBRARIES optimized "${LIBS_BINARY_DIR}/sdl2/lib/${CMAKE_STATIC_LIBRARY_PREFIX}SDL2main${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${LIBS_BINARY_DIR}/sdl2/lib/${CMAKE_STATIC_LIBRARY_PREFIX}SDL2maind${CMAKE_STATIC_LIBRARY_SUFFIX}")
		if(MSVC)
			set(SDL2_BUNDLED_LIBRARIES ${SDL2_BUNDLED_LIBRARIES} optimized "${LIBS_BINARY_DIR}/sdl2/lib/${CMAKE_STATIC_LIBRARY_PREFIX}SDL2-static${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${LIBS_BINARY_DIR}/sdl2/lib/${CMAKE_STATIC_LIBRARY_PREFIX}SDL2-staticd${CMAKE_STATIC_LIBRARY_SUFFIX}")
		else()
			set(SDL2_BUNDLED_LIBRARIES ${SDL2_BUNDLED_LIBRARIES} optimized "${LIBS_BINARY_DIR}/sdl2/lib/${CMAKE_STATIC_LIBRARY_PREFIX}SDL2${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${LIBS_BINARY_DIR}/sdl2/lib/${CMAKE_STATIC_LIBRARY_PREFIX}SDL2d${CMAKE_STATIC_LIBRARY_SUFFIX}")
		endif()
	elseif (ANDROID)
		set(SDL2_BUNDLED_LIBRARIES "${LIBS_BINARY_DIR}/sdl2/${LIBS_LIB_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}SDL2${CMAKE_STATIC_LIBRARY_SUFFIX}")
	else()
		set(SDL2_BUNDLED_LIBRARIES optimized "${LIBS_BINARY_DIR}/sdl2/${LIBS_LIB_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}SDL2${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${LIBS_BINARY_DIR}/sdl2/${LIBS_LIB_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}SDL2d${CMAKE_STATIC_LIBRARY_SUFFIX}")
	endif()

	etl_setup_cmake_args(SDL_CMAKE_ARGS
			-DSDL_RENDER_D3D=OFF -DSDL_RENDER_METAL=OFF -DSDL_RENDER=OFF
			-DSDL_DUMMYVIDEO=OFF -DSDL_KMSDRM=OFF -DSDL_SHARED=OFF
			-DSDL_SNDIO=OFF -DSDL_LIBC=ON -DSDL_PIPEWIRE=OFF -DSDL_JACK=OFF)

	if(FEATURE_RENDERER1 OR FEATURE_RENDERER2)
		list(APPEND SDL_CMAKE_ARGS -DSDL_OPENGL=ON)
	else()
		list(APPEND SDL_CMAKE_ARGS -DSDL_OPENGL=OFF)
	endif()

	# Wayland requires OpenglES support so that's why its enabled here.
	if(FEATURE_RENDERER_GLES OR (UNIX AND NOT APPLE))
		list(APPEND SDL_CMAKE_ARGS -DSDL_OPENGLES=ON)
	else()
		list(APPEND SDL_CMAKE_ARGS -DSDL_OPENGLES=OFF)
	endif()

	if(FEATURE_RENDERER_VULKAN)
		list(APPEND SDL_CMAKE_ARGS -DSDL_VULKAN=ON)
	else()
		list(APPEND SDL_CMAKE_ARGS -DSDL_VULKAN=OFF)
	endif()

	if(APPLE)
		# Bye bye X11
		list(APPEND SDL_CMAKE_ARGS -DSDL_VIDEO_X11=OFF -DSDL_X11=OFF -DSDL_VIDEO_X11_XINPUT=OFF -DSDL_WAYLAND=OFF -DSDL_METAL=OFF -DSDL_COCOA=ON)
	elseif(UNIX)
		list(APPEND SDL_CMAKE_ARGS -DSDL_X11=ON -DSDL_VIDEO_X11=ON -DSDL_VIDEO_X11_XINPUT=ON -DSDL_WAYLAND=ON)
	elseif(WIN32)
		list(APPEND SDL_CMAKE_ARGS -DSDL_FORCE_STATIC_VCRT=ON)
	endif()

	etl_find_lib_path(SDL2_BUNDLED_LIBRARIES _SDL_OUTPUT)

	ExternalProject_Add(bundled_sdl
			URL https://github.com/libsdl-org/SDL/releases/download/release-2.30.9/SDL2-2.30.9.tar.gz
			URL_HASH MD5=57393a5e1a46dd19ae40968a301c70a3
			PREFIX ${LIBS_BINARY_DIR}/sdl2
			BUILD_BYPRODUCTS ${_SDL_OUTPUT}
			CMAKE_ARGS ${SDL_CMAKE_ARGS}
	)
	set_target_properties(bundled_sdl PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})

	add_dependencies(bundled_sdl_int bundled_sdl)
	target_link_libraries(bundled_sdl_int INTERFACE ${SDL2_BUNDLED_LIBRARIES})
	target_include_directories(bundled_sdl_int INTERFACE "${LIBS_BINARY_DIR}/sdl2/include")
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
	target_include_directories(bundled_zlib PUBLIC "${CMAKE_CURRENT_LIST_DIR}/zlib")
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
	target_include_directories(bundled_minizip PUBLIC "${CMAKE_CURRENT_LIST_DIR}/minizip")

	if(APPLE OR ANDROID)
		# The ioapi requires this since OSX already uses 64 fileapi (there is no fseek64 etc)
		# the same for Android and most BSD's
		target_compile_definitions(bundled_minizip PUBLIC USE_FILE32API)
	endif()

	if(BUNDLED_ZLIB)
		target_link_libraries(bundled_minizip bundled_zlib)
	endif(BUNDLED_ZLIB)
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
	set_target_properties(bundled_sqlite3 PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
endif()

#-----------------------------------------------------------------
# Build bundled JPEG library
#-----------------------------------------------------------------
if(BUNDLED_JPEG AND BUILD_CLIENT)
	add_library(bundled_jpeg_int INTERFACE)

	check_include_file(stddef.h HAVE_STDDEF_H)
	check_include_file(stdlib.h HAVE_STDLIB_H)

	# Set SIZEOF_SIZE_T  @SIZE_T@ for 64 or 32 bit
	if(ETL_64BITS)
		set(SIZEOF_SIZE_T 8)
	else()
		set(SIZEOF_SIZE_T 4)
	endif()

	set(binary_dir "${LIBS_BINARY_DIR}/jpegturbo")

	if(MSVC)
		set(JPEG_BUNDLED_LIBRARIES "${binary_dir}/lib/turbojpeg-static${CMAKE_STATIC_LIBRARY_SUFFIX}")
	else()
		set(JPEG_BUNDLED_LIBRARIES "${binary_dir}/lib/libturbojpeg${CMAKE_STATIC_LIBRARY_SUFFIX}")
	endif()

	set(JPEG_LIB "${CMAKE_CURRENT_LIST_DIR}/jpegturbo")

	# configure_file(${JPEG_LIB}/jconfig.h.cmake ${JPEG_LIB}/jconfig.h)
	# configure_file(${JPEG_LIB}/jconfigint.h.cmake ${JPEG_LIB}/jconfigint.h)

	etl_find_lib_path(JPEG_BUNDLED_LIBRARIES _JPEG_OUTPUT)
	etl_setup_cmake_args(bundled_jpeg_cmake_args
			-DENABLE_SHARED=OFF -DENABLE_STATIC=ON -DREQUIRE_SIMD=OFF -DWITH_12BIT=OFF
			-DWITH_ARITH_DEC=ON -DWITH_ARITH_ENC=ON -DWITH_JAVA=OFF -DWITH_JPEG7=OFF -DWITH_JPEG8=ON
			-DWITH_MEM_SRCDST=ON -DWITH_SIMD=OFF -DWITH_TURBOJPEG=ON
	)

	ExternalProject_Add(bundled_jpeg
			PREFIX ${LIBS_BINARY_DIR}/jpegturbo
			URL	${CMAKE_CURRENT_LIST_DIR}/jpegturbo
			BUILD_BYPRODUCTS ${_JPEG_OUTPUT}
			CMAKE_ARGS ${bundled_jpeg_cmake_args}
	)

	set_target_properties(bundled_jpeg PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})

	add_dependencies(bundled_jpeg_int bundled_jpeg)
	target_include_directories(bundled_jpeg_int INTERFACE "${LIBS_BINARY_DIR}/jpegturbo/include")
	target_link_libraries(bundled_jpeg_int INTERFACE ${JPEG_BUNDLED_LIBRARIES})
endif()

#-----------------------------------------------------------------
# Build bundled PNG library
#-----------------------------------------------------------------
if(BUNDLED_PNG AND BUILD_CLIENT)
	add_library(bundled_png_int INTERFACE)

	set(binary_dir "${LIBS_BINARY_DIR}/libpng")
	if(MSVC)
		set(PNG_BUNDLED_LIBRARIES optimized "${binary_dir}/lib/libpng16_static${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${binary_dir}/lib/libpng16_staticd${CMAKE_STATIC_LIBRARY_SUFFIX}")
	elseif(ANDROID)
		set(PNG_BUNDLED_LIBRARIES optimized "${binary_dir}/lib/libpng16${CMAKE_STATIC_LIBRARY_SUFFIX}" debug "${binary_dir}/lib/libpng16d${CMAKE_STATIC_LIBRARY_SUFFIX}")
	else()
		set(PNG_BUNDLED_LIBRARIES "${binary_dir}/lib/libpng${CMAKE_STATIC_LIBRARY_SUFFIX}")
	endif()

	if(BUNDLED_ZLIB)
		set(ZLIB_INCLUDE_DIR "${CMAKE_CURRENT_LIST_DIR}/zlib")
	endif()

	# FIXME: re-test this when a new version of libpng is used
	# as of 2022 with an aarch64 mac the build fails due to the optimizations only being available for lnx
	set(PNG_OPTIMIZATION ON)
	if(APPLE AND ETL_ARM)
		set(PNG_OPTIMIZATION OFF)
	endif()

	etl_find_lib_path(PNG_BUNDLED_LIBRARIES _PNG_OUTPUT)

	etl_setup_cmake_args(bundled_png_cmake_args
		-DPNG_SHARED=OFF -DPNG_STATIC=ON -DPNG_FRAMEWORK=OFF
		-DZLIB_ROOT=${ZLIB_INCLUDE_DIR} -DZLIB_LIBRARY=${ZLIB_INCLUDE_DIR} -DZLIB_INCLUDE_DIR=${ZLIB_INCLUDE_DIR} -DZLIB_USE_STATIC_LIBS=ON -DPNG_TOOLS=OFF -DPNG_TESTS=OFF
		-DPNG_FRAMEWORK=OFF -DPNG_DEBUG=OFF -DPNG_HARDWARE_OPTIMIZATIONS=${PNG_OPTIMIZATION} -DAWK=OFF
	)

	ExternalProject_Add(bundled_png
			URL	${CMAKE_CURRENT_LIST_DIR}/libpng
			BUILD_BYPRODUCTS ${_PNG_OUTPUT}
			PREFIX ${LIBS_BINARY_DIR}/libpng
			CMAKE_ARGS ${bundled_png_cmake_args}
	)
	set_target_properties(bundled_png PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})

	add_dependencies(bundled_png_int bundled_png)
	target_include_directories(bundled_png_int INTERFACE "${LIBS_DOWNLOAD_SRC_DIR}/libpng/include")
	target_link_libraries(bundled_png_int INTERFACE ${PNG_BUNDLED_LIBRARIES})
endif()

#-----------------------------------------------------------------
# Build bundled Freetype library
#-----------------------------------------------------------------
if(BUNDLED_FREETYPE AND BUILD_CLIENT)
	add_library(bundled_freetype_int INTERFACE)

	set(binary_dir "${LIBS_BINARY_DIR}/freetype")
	if(MSVC)
		set(BUNDLED_FREETYPE_LIBRARIES "${binary_dir}/lib/freetype${CMAKE_STATIC_LIBRARY_SUFFIX}")
	else()
		set(BUNDLED_FREETYPE_LIBRARIES "${binary_dir}/lib/libfreetype${CMAKE_STATIC_LIBRARY_SUFFIX}")
	endif()

	etl_find_lib_path(BUNDLED_FREETYPE_LIBRARIES _FREETYPE_OUTPUT)
	etl_setup_cmake_args(BUNDLED_FREETYPE_CMAKE_ARGS
			DCMAKE_DISABLE_FIND_PACKAGE_ZLIB=ON -DCMAKE_DISABLE_FIND_PACKAGE_BZip2=ON -DCMAKE_DISABLE_FIND_PACKAGE_PNG=ON
			-DCMAKE_DISABLE_FIND_PACKAGE_HarfBuzz=ON -DCMAKE_DISABLE_FIND_PACKAGE_BrotliDec=ON
			-DFT_WITH_ZLIB=OFF -DFT_WITH_BZIP2=OFF -DFT_WITH_PNG=OFF -DFT_WITH_HARFBUZZ=OFF -DFT_WITH_BROTLI=OFF -DDISABLE_FORCE_DEBUG_POSTFIX=ON
	)

	ExternalProject_Add(bundled_freetype
			URL	${CMAKE_CURRENT_LIST_DIR}/freetype
			PREFIX ${binary_dir}
			BUILD_BYPRODUCTS ${_FREETYPE_OUTPUT}
			CMAKE_ARGS ${BUNDLED_FREETYPE_CMAKE_ARGS}
	)
	set_target_properties(bundled_freetype PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})

	add_dependencies(bundled_freetype_int bundled_freetype)
	target_include_directories(bundled_freetype_int INTERFACE "${binary_dir}/include/freetype2")
	target_link_libraries(bundled_freetype_int INTERFACE ${BUNDLED_FREETYPE_LIBRARIES})
endif()

#-----------------------------------------------------------------
# Build bundled Theora library
#-----------------------------------------------------------------
if(BUNDLED_THEORA AND BUILD_CLIENT)
	set(THEORA_SRC_DIR "${CMAKE_CURRENT_LIST_DIR}/theora/lib")
	FILE(GLOB THEORA_SRC
			"${THEORA_SRC_DIR}/apiwrapper.c"
			"${THEORA_SRC_DIR}/bitpack.c"
			"${THEORA_SRC_DIR}/decapiwrapper.c"
			"${THEORA_SRC_DIR}/decinfo.c"
			"${THEORA_SRC_DIR}/decode.c"
			"${THEORA_SRC_DIR}/dequant.c"
			"${THEORA_SRC_DIR}/fragment.c"
			"${THEORA_SRC_DIR}/huffdec.c"
			"${THEORA_SRC_DIR}/idct.c"
			"${THEORA_SRC_DIR}/info.c"
			"${THEORA_SRC_DIR}/internal.c"
			"${THEORA_SRC_DIR}/quant.c"
			"${THEORA_SRC_DIR}/state.c"
			"${CMAKE_CURRENT_LIST_DIR}/theora/lib/*.h"
			)

	# This makes the MSVC build a happier camper
	LIST(REMOVE_ITEM THEORA_SRC ${CMAKE_CURRENT_LIST_DIR}/theora/lib/encoder_disabled.c)

	# if we are building an universal package, this would need a lot more fiddling about to make it work correctly
	if(ETL_X86 AND (ETL_32BITS OR ETL_64BITS) AND (ETL_ARCH_COUNT EQUAL 1))
		set(USE_THEORA_ASM 1)
		message(STATUS "Enabling theora ASM")
		if(MSVC)
			set(THEORA_SRC_ASM_DIR ${THEORA_SRC_DIR}/x86_vc)
		else()
			set(THEORA_SRC_ASM_DIR ${THEORA_SRC_DIR}/x86)
		endif()
		FILE(GLOB THEORA_ASM_SRC
				"${THEORA_SRC_ASM_DIR}/mmxidct.c"
				"${THEORA_SRC_ASM_DIR}/mmxfrag.c"
				"${THEORA_SRC_ASM_DIR}/mmxstate.c"
				"${THEORA_SRC_ASM_DIR}/x86state.c"
				"${THEORA_SRC_ASM_DIR}/*.h"
				)

		LIST(APPEND THEORA_SRC ${THEORA_ASM_SRC})
	else()
		message(STATUS "Disabling theora ASM")
		set(USE_THEORA_ASM 0)
	endif()

	include_directories("${CMAKE_CURRENT_LIST_DIR}/theora/include")
	add_library(bundled_theora STATIC ${THEORA_SRC})
	target_link_libraries(bundled_theora PUBLIC bundled_ogg_full)

	if (USE_THEORA_ASM AND NOT ETL_WIN64)
		if (ETL_32BITS OR ETL_64BITS)
			target_compile_definitions(bundled_theora PUBLIC OC_X86_ASM)
		endif()

		if(ETL_64BITS)
			target_compile_definitions(bundled_theora PUBLIC OC_X86_64_ASM)
		endif()
	endif()

	set_target_properties(bundled_theora PROPERTIES FOLDER ${BUNDLED_TARGETS_FOLDER})
endif()

if(BUNDLED_CJSON)
	add_library(bundled_cjson STATIC "${CMAKE_CURRENT_LIST_DIR}/cjson/cJSON.c")
	set_property(TARGET bundled_cjson PROPERTY POSITION_INDEPENDENT_CODE ON)
	target_include_directories(bundled_cjson PUBLIC "${CMAKE_CURRENT_LIST_DIR}/cjson/")
	target_compile_definitions(bundled_cjson PUBLIC BUNDLED_CJSON)
endif()
