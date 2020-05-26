#
# Download sqlite3 amalgamation sources from https://www.sqlite.org/download.html
#
cmake_minimum_required(VERSION 2.8)

#project(sqlite3)

option(SQLITE_BUILD_STATIC        "Build SQLite3 static library" ON)
option(SQLITE_BUILD_SHARED        "Build SQLite3 shared library" OFF)
option(WITH_SQLITE_DEBUG          "Build SQLite3 debug features" OFF)
option(WITH_SQLITE_MEMDEBUG       "Build SQLite3 memory debug features" OFF)
option(WITH_SQLITE_RTREE          "Build R*Tree index extension" OFF)
option(WITH_SQLITE_THREADSAFE     "Build SQLite3 threadsafe" OFF)

#set(INSTALL_BIN_DIR "${CMAKE_INSTALL_PREFIX}/bin" CACHE PATH "Installation directory for executables")
#set(INSTALL_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib" CACHE PATH "Installation directory for libraries")
#set(INSTALL_INC_DIR "${CMAKE_INSTALL_PREFIX}/include" CACHE PATH "Installation directory for headers")

set(SQLITE3_SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR})

# detect version
file(STRINGS "${SQLITE3_SOURCE_DIR}/src/sqlite3.h" _sqlite_api_h_VER_STRING REGEX ".*#define[ ]+SQLITE_VERSION[ ]+")
string(REGEX MATCH "[0-9\\.]+" SQLITE_VER_STRING ${_sqlite_api_h_VER_STRING})
string(REGEX MATCHALL "[0-9]+" _sqlite_ver_LIST "${SQLITE_VER_STRING}")
list(LENGTH _sqlite_ver_LIST _sqlite_list_len)
list(GET _sqlite_ver_LIST 0 SQLITE_VER_MAJOR)
list(GET _sqlite_ver_LIST 1 SQLITE_VER_MINOR)
list(GET _sqlite_ver_LIST 2 SQLITE_VER_PATCH)
if(_sqlite_list_len EQUAL 4)
    list(GET _sqlite_ver_LIST 3 SQLITE_VER_PATCHLEVEL)
    message("Patch level: ${SQLITE_VER_PATCHLEVEL}")
endif()
message("SQLite3 version = ${SQLITE_VER_STRING}")

set(SQLITE_DYN_NAME "sqlite${SQLITE_VER_MAJOR}")
set(SQLITE_STATIC_NAME "bundled_${SQLITE_DYN_NAME}")

# os specific
if(WIN32)
    set(SQLITE_WIN_BUILD ON)
else()
    set(SQLITE_WIN_BUILD OFF)

	# FIXME/REWORK: rework this, split into linux/unix/apple, cross-compile

	#set(CMAKE_SYSTEM_PROCESSOR i386)
	#message(STATUS "Forcing ${CMAKE_SYSTEM_PROCESSOR} to cross compile 32bit")
	#set_property(GLOBAL PROPERTY FIND_LIBRARY_USE_LIB64_PATHS OFF)
	#set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -m32")
	#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -m32")
	#set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -m32")
	#set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -m32 -ldl")
	#set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -m32 -ldl")

	set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -ldl")
	# probably not needed
	#set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -ldl")
endif()

if(MINGW OR UNIX)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-attributes")

	# this is required for bundled 64bit sqlite3 lib
	# http://stackoverflow.com/questions/7216244/why-is-fpic-absolutely-necessary-on-64-and-not-on-32bit-platforms
	if(NOT CROSS_COMPILE32)
		set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC")
	endif(NOT CROSS_COMPILE32)
endif()

# add include path for project
include_directories(${SQLITE3_SOURCE_DIR}/src)

set(SRC_LIB_FILE ${SQLITE3_SOURCE_DIR}/src/sqlite${SQLITE_VER_MAJOR}.c)
file(GLOB HDR_FILES ${SQLITE3_SOURCE_DIR}/src/*.h)

# set explicit fast-math flag for sqlite3 (required for floating point support)
set_source_files_properties(HDR_FILES PROPERTIES COMPILE_FLAGS -ffast-math)
add_definitions(-DSQLITE_HAVE_ISNAN=1) # required for -ffast-math with GCC

# adding compilation flags depending on options
if(WITH_SQLITE_DEBUG)
    add_definitions(-DSQLITE_DEBUG)
endif()
if(WITH_SQLITE_MEMDEBUG)
    add_definitions(-DSQLITE_MEMDEBUG)
endif()
if(WITH_SQLITE_RTREE)
    add_definitions(-DSQLITE_ENABLE_RTREE)
endif()

if(WITH_SQLITE_THREADSAFE)
    add_definitions(-DSQLITE_THREADSAFE=1)
else()
    message("SQLite3 threadsafe is disabled")
    add_definitions(-DSQLITE_THREADSAFE=0)
endif()

if (SQLITE_BUILD_STATIC)
    # build static library
    add_library(${SQLITE_STATIC_NAME} STATIC ${SRC_LIB_FILE})
endif()

if (SQLITE_BUILD_SHARED)
    # build dynamic library
    add_library(${SQLITE_DYN_NAME} SHARED ${SRC_LIB_FILE})
    if (SQLITE_WIN_BUILD)
        #then we do dll library, so need to export api
        set_target_properties(${SQLITE_DYN_NAME} PROPERTIES DEFINE_SYMBOL "SQLITE_API=__declspec(dllexport)")
    endif()
endif()

#if(SQLITE_BUILD_SHARED)
#    list(APPEND TO_INSTALL ${SQLITE_DYN_NAME})
#endif()
#if(SQLITE_BUILD_STATIC)
#    list(APPEND TO_INSTALL ${SQLITE_STATIC_NAME})
#endif()

#install(TARGETS ${TO_INSTALL}
#        RUNTIME DESTINATION "${INSTALL_BIN_DIR}"
#        ARCHIVE DESTINATION "${INSTALL_LIB_DIR}"
#        LIBRARY DESTINATION "${INSTALL_LIB_DIR}" )
#install(FILES ${HDR_FILES} DESTINATION "${INSTALL_INC_DIR}")
