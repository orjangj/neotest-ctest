include(FetchContent)
FetchContent_Declare(
  doctest
  GIT_REPOSITORY https://github.com/doctest/doctest.git
  GIT_TAG v2.4.11)
FetchContent_MakeAvailable(doctest)

add_executable(doctest_TEST_CASE_test TEST_CASE_test.cpp)
target_compile_features(doctest_TEST_CASE_test PRIVATE cxx_std_17)
target_link_libraries(doctest_TEST_CASE_test PRIVATE doctest::doctest)

add_executable(doctest_TEST_CASE_FIXTURE_test TEST_CASE_FIXTURE_test.cpp)
target_compile_features(doctest_TEST_CASE_FIXTURE_test PRIVATE cxx_std_17)
target_link_libraries(doctest_TEST_CASE_FIXTURE_test PRIVATE doctest::doctest)

add_executable(doctest_SCENARIO_test SCENARIO_test.cpp)
target_compile_features(doctest_SCENARIO_test PRIVATE cxx_std_17)
target_link_libraries(doctest_SCENARIO_test PRIVATE doctest::doctest)

include(${doctest_SOURCE_DIR}/scripts/cmake/doctest.cmake)

doctest_discover_tests(doctest_TEST_CASE_test)
doctest_discover_tests(doctest_TEST_CASE_FIXTURE_test)
doctest_discover_tests(doctest_SCENARIO_test)
