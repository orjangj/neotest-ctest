#include <catch2/catch_test_macros.hpp>

namespace TEST_CASE {

TEST_CASE("First", "[first]") { REQUIRE(true); }

} // namespace TEST_CASE

TEST_CASE("Second", "[second]") {
  CHECK(false);
  REQUIRE(false);
}
