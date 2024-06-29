find_package(GoogleTest REQUIRED)

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
