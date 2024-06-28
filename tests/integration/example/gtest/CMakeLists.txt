include(FetchContent)
FetchContent_Declare(
  googletest
  GIT_REPOSITORY https://github.com/google/googletest.git
  GIT_TAG v1.14.0
)
# For Windows: Prevent overriding the parent project's compiler/linker settings
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
set(BUILD_GMOCK OFF)
FetchContent_MakeAvailable(googletest)

add_executable(gtest_TEST_test TEST_test.cpp)
target_compile_features(gtest_TEST_test PRIVATE cxx_std_17)
target_link_libraries(gtest_TEST_test GTest::gtest_main)

add_executable(gtest_TEST_F_test TEST_F_test.cpp)
target_compile_features(gtest_TEST_F_test PRIVATE cxx_std_17)
target_link_libraries(gtest_TEST_F_test GTest::gtest_main)

add_executable(gtest_TEST_P_test TEST_P_test.cpp)
target_compile_features(gtest_TEST_P_test PRIVATE cxx_std_17)
target_link_libraries(gtest_TEST_P_test GTest::gtest_main)

include(GoogleTest)

gtest_discover_tests(gtest_TEST_test)
gtest_discover_tests(gtest_TEST_F_test)
gtest_discover_tests(gtest_TEST_P_test)
