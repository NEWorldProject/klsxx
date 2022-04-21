if (NOT DEFINED KLS_GLOBAL_DEFINE)
    set(KLS_GLOBAL_DEFINE TRUE)
    set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_LIST_DIR})

    macro(_kls_vcpkg_enable)
        #if (DEFINED CMAKE_TOOLCHAIN_FILE)
        #    message("Chain-loading ${CMAKE_TOOLCHAIN_FILE} with vcpkg")
        #    set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE ${CMAKE_TOOLCHAIN_FILE})
        #endif ()
        if (WIN32)
            set(_KLS_VCPKG_EXEC ${KLS_VCPKG_ROOT}/vcpkg.exe)
        else ()
            set(_KLS_VCPKG_EXEC ${KLS_VCPKG_ROOT}/vcpkg)
        endif ()
        set(CMAKE_TOOLCHAIN_FILE "${KLS_VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "")
        set(KLS_VCPKG_ENABLE TRUE)
    endmacro()

    # Require vcpkg for package management
    if (DEFINED ENV{VCPKG_ROOT})
        set(KLS_VCPKG_ROOT $ENV{VCPKG_ROOT})
        message("Vcpkg detected at ${KLS_VCPKG_ROOT}")
        _kls_vcpkg_enable()
    elseif (DEFINED KLS_VCPKG_DOWNLOAD)
        set(KLS_VCPKG_ROOT ${CMAKE_BINARY_DIR}/_vcpkg/)
        message("Vcpkg download option enabled")
        if (NOT EXISTS ${KLS_VCPKG_ROOT})
            message("Installing official vcpkg repository at ${KLS_VCPKG_ROOT}")
            execute_process(COMMAND git clone "https://github.com/microsoft/vcpkg.git" "${KLS_VCPKG_ROOT}")
            if (WIN32)
                execute_process(COMMAND ${KLS_VCPKG_ROOT}/bootstrap-vcpkg.bat WORKING_DIRECTORY ${KLS_VCPKG_ROOT})
            else ()
                execute_process(COMMAND ${KLS_VCPKG_ROOT}/bootstrap-vcpkg.sh WORKING_DIRECTORY ${KLS_VCPKG_ROOT})
            endif ()
        else()
            message("Embedded vcpkg repository found at ${KLS_VCPKG_ROOT}")
        endif ()
        _kls_vcpkg_enable()
    else ()
        message("Vcpkg not detected.")
        if (KLS_VCPKG_FORCE_OVERRIDE)
            message("Build is forced to continue without vcpkg, which is not officially supported. Good luck!")
            set(KLS_VCPKG_ENABLE FALSE)
        else ()
            message(FATAL_ERROR "Please set VCPKG_ROOT env to vcpkg root, set KLS_VCPKG_DOWNLOAD or KLS_VCPKG_FORCE_OVERRIDE to continue")
            return(-1)
        endif ()
    endif ()
endif ()

macro(kls_configure)
    if (NOT DEFINED KLS_PROJECT_DEFINE)
        set(KLS_PROJECT_DEFINE TRUE)
        message("Active vcpkg triplet is ${VCPKG_TARGET_TRIPLET}")

        # Setup Language
        if (MSVC AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 19.29.30129 AND CMAKE_VERSION VERSION_GREATER 3.20.3)
            # this change happened in CMake 3.20.4
            set(CMAKE_CXX_STANDARD 23) # /std:c++latest - unlocks the non stable cpp20 features. For new 16.11 versions
        else ()
            set(CMAKE_CXX_STANDARD 20) # /std:c++latest for msvc and -std=c++20 for everyone else.
        endif ()
        message("Configuring KLSXX on ${CMAKE_SYSTEM_NAME}/${CMAKE_SYSTEM_VERSION}")

        if (MSVC)
            # Force the use of UTF-8 charset on windows platforms.
            set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /source-charset:utf-8")
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /source-charset:utf-8")
        endif ()

        # Link the atomic library on GNU C platforms
        if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
            find_package(GNUCAtomic REQUIRED)
            link_libraries(${GCCLIBATOMIC_LIBRARY})
        endif ()

        # Check IPO Support
        cmake_policy(SET CMP0069 NEW)
        include(CheckIPOSupported)
        check_ipo_supported(RESULT KLS_IPO_SUPPORT OUTPUT _KLS_IPO_SUPPORT_MESSAGE)
        if (KLS_IPO_SUPPORT)
            message(STATUS "IPO IS SUPPORTED, ENABLED")
        else ()
            message(STATUS "IPO IS NOT SUPPORTED: ${_KLS_IPO_SUPPORT_MESSAGE}, DISABLED")
        endif ()

        # Set build output directories
        set(KLS_OUT_ROOT ${CMAKE_BINARY_DIR}/out-$<CONFIG>)
        set(KLS_OUT_SDK_DIR ${KLS_OUT_ROOT}/SDK)
        set(KLS_OUT_TEST_DIR ${KLS_OUT_ROOT}/Tests)
        set(KLS_OUT_PRODUCT_DIR ${KLS_OUT_ROOT}/Product)
        set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${KLS_OUT_SDK_DIR}/lib)
        set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${KLS_OUT_PRODUCT_DIR})
        set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${KLS_OUT_PRODUCT_DIR})

        function(kls_target NAME)
            if (KLS_IPO_SUPPORT)
                set_property(TARGET ${NAME} PROPERTY INTERPROCEDURAL_OPTIMIZATION $<$<CONFIG:Debug>:FALSE>:TRUE)
            endif ()
            if (MSVC AND IDE_INSPECTION_DEFUNCT)
                target_compile_definitions(${NAME} PRIVATE __cpp_lib_coroutine __cpp_aligned_new)
                target_compile_options(${NAME} PRIVATE /wd4005 /wd4117)
            endif ()
        endfunction()

        function(kls_add_executable_module NAME)
            add_executable(${NAME})
            kls_target(${NAME})
        endfunction()

        function(kls_add_library_module NAME ALIAS)
            add_library(${NAME} STATIC)
            kls_target(${NAME})
            add_library(${ALIAS} ALIAS ${NAME})
        endfunction()

        function(kls_add_loadable_module NAME ALIAS)
            add_library(${NAME} SHARED)
            kls_target(${NAME})
            add_library(${ALIAS} ALIAS ${NAME})
        endfunction()

        function(kls_vcpkg_package NAME)
            if (KLS_VCPKG_ENABLE)
                set(_KLS_VCPKG_PKG_TARGET ${NAME}:${VCPKG_TARGET_TRIPLET})
                execute_process(
                        COMMAND ${_KLS_VCPKG_EXEC} list ${NAME}
                        ERROR_VARIABLE _KLS_VCPKG_PKG_TEST
                        OUTPUT_VARIABLE _KLS_VCPKG_PKG_TEST
                        WORKING_DIRECTORY ${KLS_VCPKG_ROOT}
                        OUTPUT_STRIP_TRAILING_WHITESPACE
                )
                if (_KLS_VCPKG_PKG_TEST MATCHES ${NAME})
                    message("${_KLS_VCPKG_PKG_TARGET} is installed")
                else()
                    message("Installing ${_KLS_VCPKG_PKG_TARGET}")
                    execute_process(
                            COMMAND ${_KLS_VCPKG_EXEC} install ${_KLS_VCPKG_PKG_TARGET}
                            WORKING_DIRECTORY ${KLS_VCPKG_ROOT}
                    )
                endif ()
            else()
                message("skipping vcpkg package check for ${NAME}")
            endif ()
        endfunction()

        function(kls_public_source_directory TARGET DIRECTORY)
            file(GLOB_RECURSE SRC_PUB ${CMAKE_CURRENT_SOURCE_DIR}/${DIRECTORY}/*.*)
            target_include_directories(${TARGET} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/${DIRECTORY})
            target_include_directories(${TARGET} INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/${DIRECTORY})
            target_sources(${TARGET} PUBLIC ${SRC_PUB})
        endfunction()

        function(kls_module_source_directory TARGET DIRECTORY)
            file(GLOB_RECURSE SRC_MOD ${CMAKE_CURRENT_SOURCE_DIR}/${DIRECTORY}/*.*)
            target_include_directories(${TARGET} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/${DIRECTORY})
            target_sources(${TARGET} PRIVATE ${SRC_MOD})
        endfunction()

        if (NOT DEFINED KLS_DISABLE_TEST)
            if (KLS_VCPKG_ENABLE)
                kls_vcpkg_package(gtest)
                find_package(GTest CONFIG REQUIRED)
            else ()
                message("Fetching embedded googletest")
                include(FetchContent)
                FetchContent_Declare(
                        googletest
                        URL https://github.com/google/googletest/archive/refs/tags/release-1.11.0.zip
                )
                # For Windows: Prevent overriding the parent project's compiler/linker settings
                set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
                FetchContent_MakeAvailable(googletest)
            endif ()
            set(KLS_BUILD_TESTS TRUE)
            enable_testing()
        endif ()

        function(kls_define_tests TEST_NAME TEST_TARGET TEST_SOURCE_DIR)
            if (KLS_BUILD_TESTS)
                file(GLOB_RECURSE SRC_TEST ${CMAKE_CURRENT_SOURCE_DIR}/${TEST_SOURCE_DIR}/*.*)
                add_executable(${TEST_NAME} ${SRC_TEST})
                kls_target(${TEST_NAME})
                target_link_libraries(${TEST_NAME} GTest::gtest_main ${TEST_TARGET})
                set_target_properties(${TEST_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${KLS_OUT_TEST_DIR})
                include(GoogleTest)
                gtest_discover_tests(${TEST_NAME})
            endif ()
        endfunction()

        function(kls_define_modules)
            foreach(DIRECTORY IN LISTS ARGN)
                string(TOLOWER ${DIRECTORY} LOWER)
                add_subdirectory(${DIRECTORY} _1/${LOWER})
            endforeach()
        endfunction()
    endif ()
endmacro()