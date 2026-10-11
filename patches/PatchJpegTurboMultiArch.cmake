# libjpeg-turbo 3.2.0 refuses to configure when CMAKE_OSX_ARCHITECTURES
# contains more than one architecture (fat/universal builds), because its SIMD
# assembly cannot produce universal binaries.  We always build the bundled copy
# with WITH_SIMD=OFF, so no assembly is involved and the restriction does not
# apply.  This script removes that hard error from the copied source tree.
# It is idempotent and fails loudly if upstream ever changes the code it
# expects to find.
#
# Usage: cmake -DSOURCE_DIR=<jpegturbo source dir> -P PatchJpegTurboMultiArch.cmake

if(NOT SOURCE_DIR)
	message(FATAL_ERROR "SOURCE_DIR is not set")
endif()

set(_cmakelists "${SOURCE_DIR}/CMakeLists.txt")
if(NOT EXISTS "${_cmakelists}")
	message(FATAL_ERROR "${_cmakelists} does not exist")
endif()

file(READ "${_cmakelists}" _content)
string(FIND "${_content}" "contains assembly code, so it cannot be built" _found)
if(_found EQUAL -1)
	message(STATUS "Multi-arch restriction already removed or changed upstream, nothing to do")
	return()
endif()

string(REGEX REPLACE
	"message\\(FATAL_ERROR \"\\$\\{CMAKE_PROJECT_NAME\\} contains assembly code[^\"]*\"\\)"
	"message(STATUS \"Multi-arch build allowed (SIMD extensions are disabled)\")"
	_content "${_content}")

string(FIND "${_content}" "contains assembly code, so it cannot be built" _found)
if(NOT _found EQUAL -1)
	message(FATAL_ERROR "Failed to remove the multi-arch restriction from ${_cmakelists}")
endif()

file(WRITE "${_cmakelists}" "${_content}")
