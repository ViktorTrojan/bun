optionx(ENABLE_SCCACHE BOOL "If sccache should be enabled" DEFAULT ON)

if(NOT ENABLE_SCCACHE OR CACHE_STRATEGY STREQUAL "none")
  return()
endif()

find_command(
  VARIABLE
    SCCACHE_PROGRAM
  COMMAND
    sccache
  REQUIRED
    ${CI}
)

if(NOT SCCACHE_PROGRAM)
  message(WARNING "sccache not found. Your builds will be slower.")
  return()
endif()

set(SCCACHE_ARGS CMAKE_C_COMPILER_LAUNCHER CMAKE_CXX_COMPILER_LAUNCHER)
foreach(arg ${SCCACHE_ARGS})
  setx(${arg} ${SCCACHE_PROGRAM})
  list(APPEND CMAKE_ARGS -D${arg}=${${arg}})
endforeach()

setenv(SCCACHE_DIR ${CACHE_PATH}/sccache)

if(CACHE_STRATEGY STREQUAL "read-only")
  # sccache doesn't have a direct read-only mode, but we can achieve similar behavior
  # by disabling writes through the SCCACHE_NO_CACHE environment variable
  setenv(SCCACHE_NO_CACHE 0)
elseif(CACHE_STRATEGY STREQUAL "write-only")
  # For write-only, we can use SCCACHE_RECACHE to force recaching
  setenv(SCCACHE_RECACHE 1)
endif()

setenv(SCCACHE_LOG trace)

if(CI)
  # CI-specific settings
  setenv(SCCACHE_CACHE_SIZE "10G")
else()
  # Local development settings
  setenv(SCCACHE_CACHE_SIZE "100G")
endif()
