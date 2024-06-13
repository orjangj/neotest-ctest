#include <catch2/catch_test_macros.hpp>

TEST_CASE("First", "[first]") { REQUIRE(true); }

TEST_CASE("Second", "[second]") {
  CHECK(false);
  REQUIRE(false);
}
