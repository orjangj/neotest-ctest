#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN
#include <doctest/doctest.h>

class Fixture
{
};

TEST_CASE_FIXTURE(Fixture, "doctest TEST_CASE_FIXTURE ok") { REQUIRE(true); }

TEST_CASE_FIXTURE(Fixture, "doctest TEST_CASE_FIXTURE fail")
{
    CHECK(false);
    REQUIRE(false);
}
