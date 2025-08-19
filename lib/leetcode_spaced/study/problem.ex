defmodule LeetcodeSpaced.Study.Problem do
  use Ecto.Schema
  import Ecto.Changeset
  
  alias LeetcodeSpaced.Study.UrlParser

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
    |> validate_required([:url])
    |> validate_inclusion(:difficulty, ["Easy", "Medium", "Hard"], message: "must be Easy, Medium, or Hard")
    |> extract_title_from_url()
    |> put_default_difficulty()
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

  defp extract_title_from_url(changeset) do
    case get_change(changeset, :url) do
      nil -> changeset
      url ->
        case UrlParser.extract_title(url) do
          nil -> 
            add_error(changeset, :url, "must be a valid LeetCode problem URL")
          title -> 
            put_change(changeset, :title, title)
        end
    end
  end

  defp put_default_difficulty(changeset) do
    case get_field(changeset, :difficulty) do
      nil -> put_change(changeset, :difficulty, "Medium")
      _ -> changeset
    end
  end

  defp put_default_platform(changeset) do
    changeset
    |> put_change(:platform, "leetcode")
    |> put_change(:custom_problem, false)
  end
end
