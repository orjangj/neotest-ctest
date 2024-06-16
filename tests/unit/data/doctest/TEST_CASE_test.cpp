#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest/doctest.h>

namespace TEST_CASE {

TEST_CASE("First") { REQUIRE(true); }

} // namespace TEST_CASE

TEST_CASE("Second") {
  CHECK(false);
  REQUIRE(false);
}
