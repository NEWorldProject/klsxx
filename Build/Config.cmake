if (NOT DEFINED KLS_PROJECT_DEFINE)
    set(KLS_PROJECT_DEFINE TRUE)

    # Setup Language
    set(CMAKE_CXX_STANDARD 20)

    # Force the use of UTF-8 charset on windows platforms.    
    if (MSVC)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /source-charset:utf-8")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /source-charset:utf-8")
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

    function(target_enable_ipo NAME)
        if (KLS_IPO_SUPPORT)
            set_property(TARGET ${NAME} PROPERTY INTERPROCEDURAL_OPTIMIZATION $<$<CONFIG:Debug>:FALSE>:TRUE)
        endif ()
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
    endif()
endif()
