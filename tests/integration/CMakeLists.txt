cmake_minimum_required(VERSION 3.14)
project(test_sample)

# GoogleTest requires at least C++14
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(FetchContent)
FetchContent_Declare(
  googletest
  GIT_REPOSITORY https://github.com/google/googletest.git
  GIT_TAG release-1.12.1
)
# For Windows: Prevent overriding the parent project's compiler/linker settings
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

enable_testing()

add_executable(
  test_sample
  ${CMAKE_SOURCE_DIR}/src/test.cpp
)

target_link_libraries(
  test_sample
  GTest::gtest_main
)

include(GoogleTest)
gtest_discover_tests(test_sample)
