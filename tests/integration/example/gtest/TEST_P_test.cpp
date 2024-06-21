#include <gtest/gtest.h>

namespace
{

class ParameterizedBool : public testing::TestWithParam<bool>
{
};

TEST_P(ParameterizedBool, Test) { EXPECT_EQ(true, GetParam()); }

INSTANTIATE_TEST_SUITE_P(GoogleTest, ParameterizedBool, testing::Bool());

class ParameterizedRange : public testing::TestWithParam<int>
{
};

TEST_P(ParameterizedRange, Test) { EXPECT_EQ(0, GetParam()); }

INSTANTIATE_TEST_SUITE_P(GoogleTest, ParameterizedRange, testing::Range(0, 2));

class ParameterizedValues : public testing::TestWithParam<int>
{
};

TEST_P(ParameterizedValues, Test) { EXPECT_EQ(0, GetParam()); }

INSTANTIATE_TEST_SUITE_P(GoogleTest, ParameterizedValues, testing::Values(0, 1));

} // namespace
