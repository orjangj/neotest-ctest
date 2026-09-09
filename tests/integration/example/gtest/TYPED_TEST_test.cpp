#include <gtest/gtest.h>

template <typename T> class TypedFixture : public testing::Test
{
};

using MyTypes = ::testing::Types<int, double>;
TYPED_TEST_SUITE(TypedFixture, MyTypes);

TYPED_TEST(TypedFixture, Ok) { SUCCEED(); }

// Passes for `int` (4 bytes), fails for `double` (8 bytes).
TYPED_TEST(TypedFixture, BySize) { EXPECT_EQ(sizeof(TypeParam), 4u); }
