#include <catch2/catch_test_macros.hpp>

class Fixture {};

TEST_CASE_METHOD(Fixture, "First", "[first]") { REQUIRE(true); }

TEST_CASE_METHOD(Fixture, "Second", "[second]") {
  CHECK(false);
  REQUIRE(true);
}
