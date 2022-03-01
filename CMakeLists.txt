cmake_minimum_required(VERSION 3.11)

project(KLSXX)
include(${CMAKE_CURRENT_SOURCE_DIR}/Build/Config.cmake)
message("Configuring KLSXX on ${CMAKE_SYSTEM_NAME}/${CMAKE_SYSTEM_VERSION}")

add_subdirectory(Essential _1/essential)
add_subdirectory(Thread _1/thread)
add_subdirectory(Coroutine _1/coroutine)
add_subdirectory(IO _1/io)
