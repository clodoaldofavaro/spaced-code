defmodule LeetcodeSpaced.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LeetcodeSpaced.Accounts` context.
  """

  @doc """
  Generate a unique user email.
  """
  def unique_user_email, do: "some email#{System.unique_integer([:positive])}"

  @doc """
  Generate a unique user google_id.
  """
  def unique_user_google_id, do: "some google_id#{System.unique_integer([:positive])}"

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        email: unique_user_email(),
        google_id: unique_user_google_id(),
        name: "some name"
      })
      |> LeetcodeSpaced.Accounts.create_user()

    user
  end
end
