#Build the OpenGL extension wrangler
cmake_minimum_required(VERSION 3.10.3)

#project(glew)

set(GLEW_SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR})
source_group(API FILES ${API})

FILE(GLOB GLEW_FILES
	${GLEW_SOURCE_DIR}/include/GL/*.h
	${GLEW_SOURCE_DIR}/src/glew.c
)

add_library(bundled_glew STATIC ${GLEW_FILES})
target_include_directories(bundled_glew PUBLIC ${GLEW_SOURCE_DIR}/include)
target_compile_definitions(bundled_glew PUBLIC GLEW_STATIC)
set_target_properties(bundled_glew PROPERTIES LINKER_LANGUAGE C)

if(MINGW OR UNIX)
	target_compile_options(bundled_glew PRIVATE "-Wno-attributes")

	# this is required for bundled 64bit glew lib
	# http://stackoverflow.com/questions/7216244/why-is-fpic-absolutely-necessary-on-64-and-not-on-32bit-platforms
	# note: -mcmodel=large might be an option to set too
	if(CMAKE_SIZEOF_VOID_P EQUAL 8)
		set_target_properties(bundled_glew PROPERTIES POSITION_INDEPENDENT_CODE ON)
	endif()
endif()

#install(TARGETS glew
#	LIBRARY DESTINATION "${GLEW_SOURCE_DIR}/lib/"
#	ARCHIVE DESTINATION "${GLEW_SOURCE_DIR}/lib/"
#)
