if(WIN32)
	#-----------------------------------------------------------------
	# Build bundled JPEG library
	#-----------------------------------------------------------------
	if(BUNDLED_JPEG) # static
		# add_custom_command(OUTPUT ${CMAKE_SOURCE_DIR}/libs/jpeg/libjpeg.lib
			# COMMAND NMAKE /f makefile.vc setup-v10 && NMAKE /C /f makefile.vc
			# WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/libs/jpeg
		# )
		# add_custom_target(bundled_jpeg
			# DEPENDS ${CMAKE_SOURCE_DIR}/libs/jpeg/libjpeg.lib
		# )
		# set(JPEG_BUNDLED_LIBRARIES "${CMAKE_SOURCE_DIR}/libs/jpeg/libjpeg.lib" PARENT_SCOPE)
		set(JPEG_BUNDLED_LIBRARIES "${CMAKE_SOURCE_DIR}/libs/jpeg-windows/jpeg.lib" PARENT_SCOPE)
		set(JPEG_BUNDLED_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/jpeg" PARENT_SCOPE)
	endif(BUNDLED_JPEG)

	#-----------------------------------------------------------------
	# Build bundled cURL library
	#-----------------------------------------------------------------
	if(BUNDLED_CURL) # DLL
		# add_custom_command(OUTPUT ${CMAKE_SOURCE_DIR}/libs/curl/lib/release-dll/libcurl_imp.lib
			# COMMAND NMAKE /C /f Makefile vc-dll VC=vc10
			# COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/libs/curl/lib/release-dll/libcurl.dll ${CMAKE_BINARY_DIR}
			# WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/libs/curl
		# )
		# add_custom_target(bundled_curl
			# DEPENDS ${CMAKE_SOURCE_DIR}/libs/curl/lib/release-dll/libcurl_imp.lib
		# )
		# set(CURL_BUNDLED_LIBRARY "${CMAKE_SOURCE_DIR}/libs/curl/lib/release-dll/libcurl_imp.lib" PARENT_SCOPE)
		set(CURL_BUNDLED_LIBRARY "${CMAKE_SOURCE_DIR}/libs/curl-windows/libcurl.lib" PARENT_SCOPE)
		set(CURL_BUNDLED_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/curl/include" PARENT_SCOPE)
	endif(BUNDLED_CURL)

	#-----------------------------------------------------------------
	# Build bundled Lua 5.1 library
	#-----------------------------------------------------------------
	if(BUNDLED_LUA)
		set(LUA_BUNDLED_LIBRARIES "${CMAKE_SOURCE_DIR}/libs/lua-windows/lua51.lib" PARENT_SCOPE)
		set(LUA_BUNDLED_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/lua/src" PARENT_SCOPE)
	endif(BUNDLED_LUA)

	#-----------------------------------------------------------------
	# Copy bundled SDL library to the etl.exe location
	#-----------------------------------------------------------------
	if(BUNDLED_SDL) # DLL
		file(COPY ${CMAKE_SOURCE_DIR}/libs/sdl-windows/lib/x86/SDL.dll DESTINATION ${CMAKE_BINARY_DIR})
		set(SDL32_BUNDLED_LIBRARIES
			"${CMAKE_SOURCE_DIR}/libs/sdl-windows/lib/x86/SDL.lib"
			"${CMAKE_SOURCE_DIR}/libs/sdl-windows/lib/x86/SDLmain.lib" PARENT_SCOPE)
		set(SDL32_BUNDLED_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/sdl/include" PARENT_SCOPE)
	endif(BUNDLED_SDL)


	#-----------------------------------------------------------------
	# Build bundled OGG and Vorbis file library
	#-----------------------------------------------------------------
	if(BUNDLED_OGG_VORBIS)
		# OGG
		set(OGG_BUNDLED_LIBRARIES "${CMAKE_SOURCE_DIR}/libs/ogg-windows/libogg_static.lib" PARENT_SCOPE)
		set(OGG_BUNDLED_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/ogg/include" PARENT_SCOPE)
		add_custom_target(bundled_ogg
			DEPENDS ${CMAKE_SOURCE_DIR}/libs/ogg-windows/libogg_static.lib
		)
		
		set(OGG_VORBIS_BUNDLED_LIBRARIES "${CMAKE_SOURCE_DIR}/libs/ogg-windows/libvorbis_static.lib" "${CMAKE_SOURCE_DIR}/libs/ogg-windows/libvorbisfile_static.lib" PARENT_SCOPE)
		set(OGG_VORBIS_BUNDLED_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/libs/vorbis/include" PARENT_SCOPE)
		add_custom_target(bundled_ogg_vorbis
			DEPENDS ${CMAKE_SOURCE_DIR}/libs/ogg-windows/libvorbis_static.lib
			DEPENDS ${CMAKE_SOURCE_DIR}/libs/ogg-windows/libvorbisfile_static.lib
		)
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
		add_custom_command(OUTPUT ${CMAKE_SOURCE_DIR}/libs/sdl/build/.libs/libSDL.a
			COMMAND make clean || true
			# disable svga and directfb modules for cross-compiling on 64bit Debian Squeezy
			COMMAND ${CROSS_COMPILE32_FLAGS} ./configure --disable-video-svga --disable-video-directfb && make
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
