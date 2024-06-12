#include <gtest/gtest.h>

namespace TEST {

TEST(Suite, First) { ASSERT_TRUE(true); }

TEST(Suite, Second) {
  EXPECT_TRUE(false);
  ASSERT_TRUE(false);
}

} // namespace TEST

namespace TEST_F {

class Fixture : public testing::Test {};

TEST_F(Fixture, First) { ASSERT_TRUE(true); }

TEST_F(Fixture, Second) {
  EXPECT_TRUE(false);
  ASSERT_TRUE(false);
}

} // namespace TEST_F
