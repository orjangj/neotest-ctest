#include <catch2/catch_test_macros.hpp>

TEST_CASE("catch2 TEST_CASE ok", "[ok]") { REQUIRE(true); }

TEST_CASE("catch2 TEST_CASE fail", "[fail]") {
  CHECK(false);
  REQUIRE(false);
}
