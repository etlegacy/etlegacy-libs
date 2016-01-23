CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

#PROJECT(LuaSQL)

if(NOT BUNDLED_LUA)
	MESSAGE(SEND_ERROR "LuaSQL and not bundled Lua isn't supported!")
else() # BUNDELD_LUA
	SET(LUA_INCLUDE_DIR ${LUA_BUNDLED_INCLUDE_DIR})
endif(NOT BUNDLED_LUA)

set(LuaSQL_SOURCE_DIR ${CMAKE_CURRENT_LIST_DIR})

SET(LUAPACKAGE_CDIR "lib/lua/5.1" CACHE STRING "Path for Lua packaged platform specific things.")
SET(LUAPACKAGE_LDIR "share/lua/5.1" CACHE STRING "Path for Lua packages platform independent things.")

if(APPLE)
    SET(LUASQL_LINK_FLAGS "-undefined dynamic_lookup")
endif(APPLE)

INCLUDE_DIRECTORIES(${LUA_INCLUDE_DIR})

SET(LUASQL_CORE ${LuaSQL_SOURCE_DIR}/src/luasql.c)

SET(LUASQL_BACKEND ${LuaSQL_SOURCE_DIR}/src/ls_sqlite3.c)
INCLUDE_DIRECTORIES(${SQLITE3_BUNDLED_INCLUDE_DIR})
SET(LUASQL_BACKEND_LIBRARIES ${SQLITE3_LIBRARIES})

SET(LUASQL_PUBLIC_HEADERS ${LuaSQL_SOURCE_DIR}/src/luasql.h)


ADD_LIBRARY(luasql_library_module MODULE ${LUASQL_PUBLIC_HEADERS} ${LUASQL_CORE} ${LUASQL_BACKEND})
SET_TARGET_PROPERTIES(luasql_library_module PROPERTIES
	PREFIX ""
	OUTPUT_NAME "luasql"
)
SET_TARGET_PROPERTIES(luasql_library_module PROPERTIES COMPILE_FLAGS "${LUASQL_C_FLAGS}")
TARGET_LINK_LIBRARIES(luasql_library_module ${LUA_LIBRARIES} ${LUASQL_LINK_FLAGS} ${LUASQL_BACKEND_LIBRARIES})


#if(WANTS_BUILD_FRAMEWORK)
#    SET_TARGET_PROPERTIES(luasql_library_module PROPERTIES
#        FRAMEWORK TRUE
#        # FRAMEWORK_VERSION 5.1
#        #  PRIVATE_HEADER "fooPrivate.h;fooBoth.h"
#        PUBLIC_HEADER "${LUASQL_PUBLIC_HEADERS}"
#        # RESOURCE "${RESOURCE_FILES}"
#        INSTALL_NAME_DIR "@executable_path/../Frameworks"
#        BUILD_WITH_INSTALL_RPATH 1 # FIXME: User option or Xcode=1
#    )
#endif(WANTS_BUILD_FRAMEWORK)


INSTALL(TARGETS luasql_library_module DESTINATION ${LUAPACKAGE_CDIR})
INSTALL(FILES ${LUASQL_PUBLIC_HEADERS} DESTINATION include)

# Set defaults for Universal Binaries. We want 32-bit Intel/PPC on 10.4
# and 32/64-bit Intel/PPC on >= 10.5. Anything <= 10.3 doesn't support.
if(APPLE)
    # These are just defaults/recommendations, but how we want to build
    # out of the box. But the user needs to be able to change these options.
    # So we must only set the values the first time CMake is run, or we
    # will overwrite any changes the user sets.
    # FORCE is used because the options are not reflected in the UI otherwise.
    # Seems like a good place to add version specific compiler flags too.
    if(NOT LUA_CONFIG_HAS_BEEN_RUN_BEFORE)
        # This is really fragile, but CMake doesn't provide the OS system
        # version information we need. (Darwin versions can be changed
        # independently of OS X versions.)
        # It does look like CMake handles the CMAKE_OSX_SYSROOT automatically.
        if(EXISTS /Developer/SDKs/MacOSX10.5.sdk)
            SET(CMAKE_OSX_ARCHITECTURES "ppc;i386;ppc64;x86_64" CACHE STRING "Build architectures for OSX" FORCE)
            SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mmacosx-version-min=10.5" CACHE STRING "Flags used by the compiler during all build types." FORCE)
        else(EXISTS /Developer/SDKs/MacOSX10.5.sdk)
            if(EXISTS /Developer/SDKs/MacOSX10.4u.sdk)
                SET(CMAKE_OSX_ARCHITECTURES "ppc;i386" CACHE STRING "Build architectures for OSX" FORCE)
                SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mmacosx-version-min=10.4" CACHE STRING "Flags used by the compiler during all build types." FORCE)
            else(EXISTS /Developer/SDKs/MacOSX10.4u.sdk)
                # No Universal Binary support
                # Should break down further to set the -mmacosx-version-min,
                # but the SDK detection is too unreliable here.
            endif(EXISTS /Developer/SDKs/MacOSX10.4u.sdk)
        endif(EXISTS /Developer/SDKs/MacOSX10.5.sdk)
    endif(NOT LUA_CONFIG_HAS_BEEN_RUN_BEFORE)
endif(APPLE)

# This needs to be run very last so other parts of the scripts can take
# advantage of this.
if(NOT LUA_CONFIG_HAS_BEEN_RUN_BEFORE)
    SET(LUA_CONFIG_HAS_BEEN_RUN_BEFORE 1 CACHE INTERNAL "Flag to track whether this is the first time running CMake or if CMake has been configured before")
endif(NOT LUA_CONFIG_HAS_BEEN_RUN_BEFORE)
