#include <catch2/catch_test_macros.hpp>

class Fixture {};

TEST_CASE_METHOD(Fixture, "catch2 TEST_CASE_METHOD ok", "[ok]") { REQUIRE(true); }

TEST_CASE_METHOD(Fixture, "catch2 TEST_CASE_METHOD fail", "[fail]") {
  CHECK(false);
  REQUIRE(false);
}
