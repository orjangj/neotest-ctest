#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest/doctest.h>

TEST_CASE("doctest TEST_CASE ok") { REQUIRE(true); }

TEST_CASE("doctest TEST_CASE fail")
{
    CHECK(false);
    REQUIRE(false);
}
