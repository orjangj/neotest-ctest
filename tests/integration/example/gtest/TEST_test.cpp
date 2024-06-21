#include <gtest/gtest.h>

namespace
{

TEST(GoogleTest, Ok) { ASSERT_TRUE(true); }

TEST(GoogleTest, Fail)
{
    EXPECT_TRUE(false);
    ASSERT_TRUE(false);
}

} // namespace
