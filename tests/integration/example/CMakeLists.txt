cmake_minimum_required(VERSION 3.21)
project(neotest-ctest-sample LANGUAGES CXX)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(CTest)

# add_subdirectory(catch2)
# add_subdirectory(doctest)
add_subdirectory(gtest)
