#include <gtest/gtest.h>

class ParameterizedBool : public testing::TestWithParam<bool> {};

TEST_P(ParameterizedBool, Test) { EXPECT_EQ(true, GetParam()); }

INSTANTIATE_TEST_SUITE_P(P1, ParameterizedBool, testing::Bool());

class ParameterizedInt : public testing::TestWithParam<int> {};

TEST_P(ParameterizedInt, Test) { EXPECT_EQ(0, GetParam()); }

INSTANTIATE_TEST_SUITE_P(P1, ParameterizedInt, testing::Range(0,2));
INSTANTIATE_TEST_SUITE_P(P1, ParameterizedInt, testing::Values(2,3));
