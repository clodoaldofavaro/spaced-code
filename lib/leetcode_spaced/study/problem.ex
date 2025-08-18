defmodule LeetcodeSpaced.Study.Problem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "problems" do
    field :title, :string
    field :url, :string
    field :old_leetcode_id, :integer
    field :difficulty, :string
    field :topics, {:array, :string}
    field :platform, :string
    field :platform_id, :string
    field :description, :string
    field :custom_problem, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(problem, attrs) do
    problem
    |> cast(attrs, [:title, :url, :old_leetcode_id, :difficulty, :topics, :platform, :platform_id, :description, :custom_problem])
    |> validate_required([:title, :url, :difficulty])
    |> validate_inclusion(:difficulty, ["Easy", "Medium", "Hard"])
    |> put_default_topics()
    |> put_default_platform()
  end

  defp put_default_topics(changeset) do
    case get_field(changeset, :topics) do
      nil -> put_change(changeset, :topics, [])
      topics when is_list(topics) -> changeset
      _ -> put_change(changeset, :topics, [])
    end
  end

  defp put_default_platform(changeset) do
    changeset
    |> put_change(:platform, "leetcode")
    |> put_change(:custom_problem, false)
  end
end
