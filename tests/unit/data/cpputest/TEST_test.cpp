#include <CppUTest/TestHarness.h>

namespace TEST {

TEST_GROUP(Suite){};

TEST(Suite, First) { CHECK(true); }

TEST(Suite, Second) {
  CHECK_EQUAL(2, 1);
  CHECK(false);
}

} // namespace TEST
