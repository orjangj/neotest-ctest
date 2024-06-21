#include <catch2/catch_test_macros.hpp>

SCENARIO("catch2 SCENARIO ok")
{
    GIVEN("A counter starting at zero")
    {
        auto v = 0;

        WHEN("Incremented by 1")
        {
            v++;

            THEN("The value should equal 1") { REQUIRE(v == 1); }
        }
    }
}

SCENARIO("catch2 SCENARIO fail")
{
    GIVEN("A counter starting at zero")
    {
        auto v = 0;

        WHEN("Incremented by 1")
        {
            v++;

            THEN("The value should equal 1") { REQUIRE(v == 0); }
        }
    }
}
