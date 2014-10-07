#Build the OpenGL extension wrangler
cmake_minimum_required(VERSION 2.8)

#project(glew)

if(MINGW OR UNIX)
  	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-attributes")

	# this is required for bundled 64bit glew lib
	# http://stackoverflow.com/questions/7216244/why-is-fpic-absolutely-necessary-on-64-and-not-on-32bit-platforms
	# note: -mcmodel=large might be an option to set too
	if(NOT CROSS_COMPILE32)
		set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC")
	endif(NOT CROSS_COMPILE32)
endif()

set(GLEW_SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR})
include_directories( ${GLEW_SOURCE_DIR}/include)
source_group(API FILES ${API})

FILE(GLOB GLEW_FILES
	${GLEW_SOURCE_DIR}/include/GL/*.h
	${GLEW_SOURCE_DIR}/src/glew.c
)

add_library(bundled_glew STATIC ${GLEW_FILES})
set_target_properties(bundled_glew PROPERTIES
	LINKER_LANGUAGE C
	COMPILE_DEFINITIONS "GLEW_STATIC"
	#ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
)

#install(TARGETS glew
#	LIBRARY DESTINATION "${GLEW_SOURCE_DIR}/lib/"
#	ARCHIVE DESTINATION "${GLEW_SOURCE_DIR}/lib/"
#)
