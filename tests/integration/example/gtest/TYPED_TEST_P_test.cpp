#include <gtest/gtest.h>

template <typename T> class TypedFixtureP : public testing::Test
{
};

TYPED_TEST_SUITE_P(TypedFixtureP);

TYPED_TEST_P(TypedFixtureP, Ok) { SUCCEED(); }

// Passes for `int` (4 bytes), fails for `double` (8 bytes).
TYPED_TEST_P(TypedFixtureP, BySize) { EXPECT_EQ(sizeof(TypeParam), 4u); }

REGISTER_TYPED_TEST_SUITE_P(TypedFixtureP, Ok, BySize);

using MyTypes = ::testing::Types<int, double>;
INSTANTIATE_TYPED_TEST_SUITE_P(P1, TypedFixtureP, MyTypes);
