#Build the OpenGL extension wrangler
cmake_minimum_required(VERSION 2.8)

#project(glew)

if(MINGW OR UNIX)
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-attributes")
endif()

set(GLEW_SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR})
include_directories( ${GLEW_SOURCE_DIR}/include)
source_group(API FILES ${API})

FILE(GLOB GLEW_FILES
	${GLEW_SOURCE_DIR}/include/GL/*.h
	${GLEW_SOURCE_DIR}/src/glew.c
)

add_library(glew STATIC ${GLEW_FILES})
set_target_properties(glew PROPERTIES
	LINKER_LANGUAGE C
	COMPILE_DEFINITIONS "GLEW_STATIC"
	#ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
)

#install(TARGETS glew
#	LIBRARY DESTINATION "${GLEW_SOURCE_DIR}/lib/"
#	ARCHIVE DESTINATION "${GLEW_SOURCE_DIR}/lib/"
#)
