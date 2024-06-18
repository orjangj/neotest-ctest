#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest/doctest.h>

class Fixture {};

TEST_CASE_FIXTURE(Fixture, "First") { REQUIRE(true); }

TEST_CASE_FIXTURE(Fixture, "Second") {
  CHECK(false);
  REQUIRE(true);
}
