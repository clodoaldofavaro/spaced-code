defmodule LeetcodeSpaced.Study.UrlParser do
  @moduledoc """
  Utility functions for parsing LeetCode URLs and extracting problem information.
  """

  @doc """
  Extracts the problem title from a LeetCode URL.
  
  ## Examples
  
      iex> LeetcodeSpaced.Study.UrlParser.extract_title("https://leetcode.com/problems/flood-fill/description/")
      "Flood Fill"
      
      iex> LeetcodeSpaced.Study.UrlParser.extract_title("https://leetcode.com/problems/two-sum/")
      "Two Sum"
      
      iex> LeetcodeSpaced.Study.UrlParser.extract_title("https://leetcode.com/problems/3sum-closest/")
      "3sum Closest"
      
      iex> LeetcodeSpaced.Study.UrlParser.extract_title("invalid-url")
      nil
  """
  def extract_title(url) when is_binary(url) do
    case extract_problem_slug(url) do
      nil -> nil
      slug -> slug_to_title(slug)
    end
  end

  def extract_title(_), do: nil

  @doc """
  Extracts the problem slug from a LeetCode URL.
  
  ## Examples
  
      iex> LeetcodeSpaced.Study.UrlParser.extract_problem_slug("https://leetcode.com/problems/flood-fill/description/")
      "flood-fill"
      
      iex> LeetcodeSpaced.Study.UrlParser.extract_problem_slug("https://leetcode.com/problems/two-sum/")
      "two-sum"
  """
  def extract_problem_slug(url) when is_binary(url) do
    # Regex to match LeetCode problem URLs and extract the slug
    case Regex.run(~r/leetcode\.com\/problems\/([^\/\?]+)/, url) do
      [_full_match, slug] -> slug
      _ -> nil
    end
  end

  def extract_problem_slug(_), do: nil

  @doc """
  Converts a problem slug to a human-readable title.
  
  ## Examples
  
      iex> LeetcodeSpaced.Study.UrlParser.slug_to_title("flood-fill")
      "Flood Fill"
      
      iex> LeetcodeSpaced.Study.UrlParser.slug_to_title("two-sum")
      "Two Sum"
      
      iex> LeetcodeSpaced.Study.UrlParser.slug_to_title("3sum-closest")
      "3sum Closest"
  """
  def slug_to_title(slug) when is_binary(slug) do
    slug
    |> String.split("-")
    |> Enum.map(&capitalize_word/1)
    |> Enum.join(" ")
  end

  def slug_to_title(_), do: nil

  # Private function to capitalize words, handling special cases
  defp capitalize_word(word) do
    cond do
      # Handle numbers at the start of words (like "3sum")
      Regex.match?(~r/^\d/, word) -> word
      # Handle Roman numerals (common in LeetCode problems)
      word in ["i", "ii", "iii", "iv", "v", "vi", "vii", "viii", "ix", "x"] -> String.upcase(word)
      # Regular capitalization
      true -> String.capitalize(word)
    end
  end

  @doc """
  Validates if a URL is a valid LeetCode problem URL.
  
  ## Examples
  
      iex> LeetcodeSpaced.Study.UrlParser.valid_leetcode_url?("https://leetcode.com/problems/flood-fill/")
      true
      
      iex> LeetcodeSpaced.Study.UrlParser.valid_leetcode_url?("https://google.com")
      false
  """
  def valid_leetcode_url?(url) when is_binary(url) do
    Regex.match?(~r/^https?:\/\/(www\.)?leetcode\.com\/problems\/[^\/\?]+/, url)
  end

  def valid_leetcode_url?(_), do: false
end