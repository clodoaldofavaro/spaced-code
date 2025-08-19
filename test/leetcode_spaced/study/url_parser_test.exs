defmodule LeetcodeSpaced.Study.UrlParserTest do
  use ExUnit.Case, async: true
  
  alias LeetcodeSpaced.Study.UrlParser

  describe "extract_title/1" do
    test "extracts title from standard LeetCode URL" do
      assert UrlParser.extract_title("https://leetcode.com/problems/flood-fill/description/") == "Flood Fill"
      assert UrlParser.extract_title("https://leetcode.com/problems/two-sum/") == "Two Sum"
      assert UrlParser.extract_title("https://leetcode.com/problems/add-two-numbers/") == "Add Two Numbers"
    end

    test "handles URLs with numbers at the start" do
      assert UrlParser.extract_title("https://leetcode.com/problems/3sum-closest/") == "3sum Closest"
      assert UrlParser.extract_title("https://leetcode.com/problems/4sum/") == "4sum"
    end

    test "handles complex problem names" do
      assert UrlParser.extract_title("https://leetcode.com/problems/longest-palindromic-substring/") == "Longest Palindromic Substring"
      assert UrlParser.extract_title("https://leetcode.com/problems/merge-k-sorted-lists/") == "Merge K Sorted Lists"
    end

    test "handles URLs with query parameters" do
      assert UrlParser.extract_title("https://leetcode.com/problems/flood-fill/?tab=description") == "Flood Fill"
    end

    test "handles www subdomain" do
      assert UrlParser.extract_title("https://www.leetcode.com/problems/flood-fill/") == "Flood Fill"
    end

    test "handles http (non-secure) URLs" do
      assert UrlParser.extract_title("http://leetcode.com/problems/flood-fill/") == "Flood Fill"
    end

    test "returns nil for invalid URLs" do
      assert UrlParser.extract_title("invalid-url") == nil
      assert UrlParser.extract_title("https://google.com") == nil
      assert UrlParser.extract_title("https://leetcode.com/") == nil
      assert UrlParser.extract_title("https://leetcode.com/problems/") == nil
    end

    test "returns nil for non-string inputs" do
      assert UrlParser.extract_title(nil) == nil
      assert UrlParser.extract_title(123) == nil
      assert UrlParser.extract_title([]) == nil
    end
  end

  describe "extract_problem_slug/1" do
    test "extracts slug from various URL formats" do
      assert UrlParser.extract_problem_slug("https://leetcode.com/problems/flood-fill/description/") == "flood-fill"
      assert UrlParser.extract_problem_slug("https://leetcode.com/problems/two-sum/") == "two-sum"
      assert UrlParser.extract_problem_slug("https://leetcode.com/problems/add-two-numbers/solutions/") == "add-two-numbers"
    end

    test "returns nil for invalid URLs" do
      assert UrlParser.extract_problem_slug("https://google.com") == nil
      assert UrlParser.extract_problem_slug("invalid") == nil
    end
  end

  describe "slug_to_title/1" do
    test "converts simple slugs to titles" do
      assert UrlParser.slug_to_title("flood-fill") == "Flood Fill"
      assert UrlParser.slug_to_title("two-sum") == "Two Sum"
      assert UrlParser.slug_to_title("add-two-numbers") == "Add Two Numbers"
    end

    test "handles numbers at the start" do
      assert UrlParser.slug_to_title("3sum-closest") == "3sum Closest"
      assert UrlParser.slug_to_title("4sum") == "4sum"
    end

    test "handles Roman numerals" do
      assert UrlParser.slug_to_title("roman-to-integer") == "Roman To Integer"
      assert UrlParser.slug_to_title("integer-to-roman") == "Integer To Roman"
    end

    test "returns nil for invalid input" do
      assert UrlParser.slug_to_title(nil) == nil
      assert UrlParser.slug_to_title(123) == nil
    end
  end

  describe "valid_leetcode_url?/1" do
    test "validates correct LeetCode URLs" do
      assert UrlParser.valid_leetcode_url?("https://leetcode.com/problems/flood-fill/") == true
      assert UrlParser.valid_leetcode_url?("https://www.leetcode.com/problems/two-sum/") == true
      assert UrlParser.valid_leetcode_url?("http://leetcode.com/problems/add-two-numbers/") == true
      assert UrlParser.valid_leetcode_url?("https://leetcode.com/problems/3sum-closest/description/") == true
    end

    test "rejects invalid URLs" do
      assert UrlParser.valid_leetcode_url?("https://google.com") == false
      assert UrlParser.valid_leetcode_url?("https://leetcode.com/") == false
      assert UrlParser.valid_leetcode_url?("https://leetcode.com/problems/") == false
      assert UrlParser.valid_leetcode_url?("invalid-url") == false
    end

    test "rejects non-string inputs" do
      assert UrlParser.valid_leetcode_url?(nil) == false
      assert UrlParser.valid_leetcode_url?(123) == false
      assert UrlParser.valid_leetcode_url?([]) == false
    end
  end
end