include(FetchContent)
FetchContent_Declare(
  catch
  GIT_REPOSITORY https://github.com/catchorg/Catch2.git
  GIT_TAG v3.6.0)
FetchContent_MakeAvailable(catch)

add_executable(catch2_TEST_CASE_test TEST_CASE_test.cpp)
target_compile_features(catch2_TEST_CASE_test PRIVATE cxx_std_17)
target_link_libraries(catch2_TEST_CASE_test PRIVATE Catch2::Catch2WithMain)

add_executable(catch2_TEST_CASE_METHOD_test TEST_CASE_METHOD_test.cpp)
target_compile_features(catch2_TEST_CASE_METHOD_test PRIVATE cxx_std_17)
target_link_libraries(catch2_TEST_CASE_METHOD_test PRIVATE Catch2::Catch2WithMain)

add_executable(catch2_SCENARIO_test SCENARIO_test.cpp)
target_compile_features(catch2_SCENARIO_test PRIVATE cxx_std_17)
target_link_libraries(catch2_SCENARIO_test PRIVATE Catch2::Catch2WithMain)

include(Catch)

catch_discover_tests(catch2_TEST_CASE_test)
catch_discover_tests(catch2_TEST_CASE_METHOD_test)
catch_discover_tests(catch2_SCENARIO_test)
