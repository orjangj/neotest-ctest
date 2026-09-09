#include <gtest/gtest.h>

template <typename T> class TypedFixture : public testing::Test {};

using MyTypes = ::testing::Types<int, double>;
TYPED_TEST_SUITE(TypedFixture, MyTypes);

TYPED_TEST(TypedFixture, First) { ASSERT_TRUE(true); }

TYPED_TEST(TypedFixture, Second) {
  EXPECT_TRUE(false);
  ASSERT_TRUE(false);
}
