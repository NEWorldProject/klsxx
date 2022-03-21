if (NOT DEFINED KLS_PROJECT_DEFINE)
    set(KLS_PROJECT_DEFINE TRUE)

    # Setup Language
    set(CMAKE_CXX_STANDARD 20)

    if (MSVC)
    #    Force the use of UTF-8 charset on windows platforms.
    #    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /source-charset:utf-8")
    #    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /source-charset:utf-8")
    endif()

    # Link the atomic library on GNU C platforms
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        find_package(GNUCAtomic REQUIRED)
        link_libraries(${GCCLIBATOMIC_LIBRARY})
    endif()

    # Check IPO Support
    cmake_policy(SET CMP0069 NEW)
    include(CheckIPOSupported)
    check_ipo_supported(RESULT KLS_IPO_SUPPORT OUTPUT _KLS_IPO_SUPPORT_MESSAGE)
    if (KLS_IPO_SUPPORT)
        message(STATUS "IPO IS SUPPORTED, ENABLED")
    else()
        message(STATUS "IPO IS NOT SUPPORTED: ${_KLS_IPO_SUPPORT_MESSAGE}, DISABLED")
    endif()

    function(kls_target NAME)
        if (KLS_IPO_SUPPORT)
            set_property(TARGET ${NAME} PROPERTY INTERPROCEDURAL_OPTIMIZATION $<$<CONFIG:Debug>:FALSE>:TRUE)
        endif ()
        if (MSVC)
            target_compile_definitions(${NAME} PRIVATE __cpp_lib_coroutine)
            target_compile_options(${NAME} PRIVATE "/wd4005;")
        endif()
    endfunction()

    function(kls_add_library_module NAME ALIAS)
        add_library(${NAME} STATIC)
        kls_target(${NAME})
        add_library(${ALIAS} ALIAS ${NAME})
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
        include(FetchContent)
        FetchContent_Declare(
                googletest
                URL https://github.com/google/googletest/archive/refs/tags/release-1.11.0.zip
        )
        # For Windows: Prevent overriding the parent project's compiler/linker settings
        set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
        FetchContent_MakeAvailable(googletest)
        set(KLS_BUILD_TESTS TRUE)
        enable_testing()
    endif()

    function(kls_define_tests TEST_NAME TEST_TARGET TEST_SOURCE_DIR)
        if (KLS_BUILD_TESTS)
            file(GLOB_RECURSE SRC_TEST ${CMAKE_CURRENT_SOURCE_DIR}/${TEST_SOURCE_DIR}/*.*)
            add_executable(${TEST_NAME} ${SRC_TEST})
            kls_target(${TEST_NAME})
            target_link_libraries(${TEST_NAME} GTest::gtest_main ${TEST_TARGET})
            include(GoogleTest)
            gtest_discover_tests(${TEST_NAME})
        endif()
    endfunction()
endif()
