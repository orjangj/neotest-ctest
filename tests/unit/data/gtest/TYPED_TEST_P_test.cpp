#include <gtest/gtest.h>

template <typename T> class TypedFixtureP : public testing::Test {};

TYPED_TEST_SUITE_P(TypedFixtureP);

TYPED_TEST_P(TypedFixtureP, First) { ASSERT_TRUE(true); }

TYPED_TEST_P(TypedFixtureP, Second) {
  EXPECT_TRUE(false);
  ASSERT_TRUE(false);
}

REGISTER_TYPED_TEST_SUITE_P(TypedFixtureP, First, Second);

using MyTypes = ::testing::Types<int, double>;
INSTANTIATE_TYPED_TEST_SUITE_P(P1, TypedFixtureP, MyTypes);
