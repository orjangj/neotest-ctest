#include <catch2/catch_test_macros.hpp>

SCENARIO("First") {
  GIVEN("A counter starting at zero") {
    auto v = 0;

    WHEN("Incremented by 1") {
      v++;

      THEN("The value should equal 1") { REQUIRE(v == 1); }
    }
  }
}

SCENARIO("Second") {
  GIVEN("A counter starting at zero") {
    auto v = 0;

    WHEN("Incremented by 2") {
      v += 2;

      THEN("The value should equal 2") {
        CHECK(v == 1);
        REQUIRE(v == 1);
      }
    }
  }
}
