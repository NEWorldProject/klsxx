cmake_minimum_required(VERSION 3.11)

include(Build/Config.cmake)
project(KLSXX)

kls_configure()
kls_define_modules(Essential Thread Coroutine IO PHTTP Journal)
