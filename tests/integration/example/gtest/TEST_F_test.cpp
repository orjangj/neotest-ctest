#include <gtest/gtest.h>

namespace
{

class GoogleTest : public testing::Test
{
};

TEST_F(GoogleTest, Ok) { ASSERT_TRUE(true); }

TEST_F(GoogleTest, Fail)
{
    EXPECT_TRUE(false);
    ASSERT_TRUE(false);
}

} // namespace TEST_F
