#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest/doctest.h>

SCENARIO("doctest SCENARIO ok")
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

SCENARIO("doctest SCENARIO fail")
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
