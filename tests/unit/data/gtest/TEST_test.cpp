#include <gtest/gtest.h>

namespace TEST {

TEST(Suite, First) { ASSERT_TRUE(true); }

TEST(Suite, Second) {
  EXPECT_TRUE(false);
  ASSERT_TRUE(false);
}

} // namespace TEST
