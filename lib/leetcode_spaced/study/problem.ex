defmodule LeetcodeSpaced.Study.Problem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "problems" do
    field :title, :string
    field :leetcode_url, :string
    field :leetcode_id, :integer
    field :difficulty, :string
    field :topics, {:array, :string}

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(problem, attrs) do
    problem
    |> cast(attrs, [:title, :leetcode_url, :leetcode_id, :difficulty, :topics])
    |> validate_required([:title, :leetcode_url, :leetcode_id, :difficulty, :topics])
    |> unique_constraint(:leetcode_id)
  end
end
