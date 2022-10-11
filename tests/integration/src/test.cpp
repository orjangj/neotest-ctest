#include <gtest/gtest.h>

namespace test {

class TestFixture : public ::testing::Test {
protected:
  void doNothing() {}
  void fail() { EXPECT_TRUE(false); }
};

TEST_F(TestFixture, TestError) {
  doNothing();
  ASSERT_TRUE(false);
}

TEST_F(TestFixture, TestOk) {
  doNothing();
  ASSERT_TRUE(true);
}

TEST_F(TestFixture, FailInFixture) {
  doNothing();
  fail();
}

} // namespace test
