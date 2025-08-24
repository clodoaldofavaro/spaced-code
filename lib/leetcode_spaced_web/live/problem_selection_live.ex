defmodule LeetcodeSpacedWeb.ProblemSelectionLive do
  use LeetcodeSpacedWeb, :live_view
  alias LeetcodeSpaced.Study

  def mount(_params, session, socket) do
    current_user = get_current_user(session)

    if current_user do
      # Get initial data
      categories = Study.list_categories()
      difficulties = Study.list_difficulties()
      user_lists = Study.list_lists_for_user(current_user.id)

      # Get first page of problems
      result = Study.list_leetcode_problems(page: 1, per_page: 20)

      socket =
        socket
        |> assign(current_user: current_user)
        |> assign(categories: categories)
        |> assign(difficulties: difficulties)
        |> assign(user_lists: user_lists)
        |> assign(problems: result.problems)
        |> assign(total_count: result.total_count)
        |> assign(page: result.page)
        |> assign(total_pages: result.total_pages)
        |> assign(per_page: result.per_page)
        |> assign(search: "")
        |> assign(selected_difficulty: "")
        |> assign(selected_category: "")
        |> assign(selected_problems: MapSet.new())
        |> assign(show_list_modal: false)
        |> assign(show_create_list_modal: false)
        |> assign(selected_lists: [])
        |> assign(new_list_form: to_form(Study.change_list(%LeetcodeSpaced.Study.List{})))

      {:ok, socket}
    else
      {:ok, redirect(socket, to: "/")}
    end
  end

  defp get_current_user(session) do
    case session["user_id"] do
      nil -> nil
      user_id -> LeetcodeSpaced.Accounts.get_user!(user_id)
    end
  rescue
    _ -> nil
  end

  def handle_event("search", %{"search" => search}, socket) do
    result =
      Study.list_leetcode_problems(
        page: 1,
        per_page: socket.assigns.per_page,
        search: search,
        difficulty: socket.assigns.selected_difficulty,
        category: socket.assigns.selected_category
      )

    {:noreply,
     socket
     |> assign(problems: result.problems)
     |> assign(total_count: result.total_count)
     |> assign(page: result.page)
     |> assign(total_pages: result.total_pages)
     |> assign(search: search)}
  end

  def handle_event("filter_difficulty", %{"difficulty" => difficulty}, socket) do
    result =
      Study.list_leetcode_problems(
        page: 1,
        per_page: socket.assigns.per_page,
        search: socket.assigns.search,
        difficulty: difficulty,
        category: socket.assigns.selected_category
      )

    {:noreply,
     socket
     |> assign(problems: result.problems)
     |> assign(total_count: result.total_count)
     |> assign(page: result.page)
     |> assign(total_pages: result.total_pages)
     |> assign(selected_difficulty: difficulty)}
  end

  def handle_event("filter_category", %{"category" => category}, socket) do
    result =
      Study.list_leetcode_problems(
        page: 1,
        per_page: socket.assigns.per_page,
        search: socket.assigns.search,
        difficulty: socket.assigns.selected_difficulty,
        category: category
      )

    {:noreply,
     socket
     |> assign(problems: result.problems)
     |> assign(total_count: result.total_count)
     |> assign(page: result.page)
     |> assign(total_pages: result.total_pages)
     |> assign(selected_category: category)}
  end

  def handle_event("load_more", _params, socket) do
    next_page = socket.assigns.page + 1

    if next_page <= socket.assigns.total_pages do
      result =
        Study.list_leetcode_problems(
          page: next_page,
          per_page: socket.assigns.per_page,
          search: socket.assigns.search,
          difficulty: socket.assigns.selected_difficulty,
          category: socket.assigns.selected_category
        )

      {:noreply,
       socket
       |> assign(problems: socket.assigns.problems ++ result.problems)
       |> assign(page: next_page)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("toggle_problem", %{"leetcode_id" => leetcode_id}, socket) do
    leetcode_id_int = String.to_integer(leetcode_id)
    selected_problems = socket.assigns.selected_problems

    new_selected_problems =
      if MapSet.member?(selected_problems, leetcode_id_int) do
        MapSet.delete(selected_problems, leetcode_id_int)
      else
        MapSet.put(selected_problems, leetcode_id_int)
      end

    {:noreply, assign(socket, selected_problems: new_selected_problems)}
  end

  def handle_event("select_all", _params, socket) do
    all_problem_ids = Enum.map(socket.assigns.problems, & &1.leetcode_id)

    new_selected_problems =
      MapSet.union(socket.assigns.selected_problems, MapSet.new(all_problem_ids))

    {:noreply, assign(socket, selected_problems: new_selected_problems)}
  end

  def handle_event("deselect_all", _params, socket) do
    {:noreply, assign(socket, selected_problems: MapSet.new())}
  end

  def handle_event("add_to_list", _params, socket) do
    if MapSet.size(socket.assigns.selected_problems) > 0 do
      {:noreply, assign(socket, show_list_modal: true)}
    else
      {:noreply, put_flash(socket, :error, "Please select at least one problem")}
    end
  end

  def handle_event("close_list_modal", _params, socket) do
    {:noreply, assign(socket, show_list_modal: false)}
  end

  def handle_event("toggle_list_selection", %{"list_id" => list_id}, socket) do
    list_id_int = String.to_integer(list_id)
    selected_lists = socket.assigns.selected_lists

    new_selected_lists =
      if list_id_int in selected_lists do
        List.delete(selected_lists, list_id_int)
      else
        [list_id_int | selected_lists]
      end

    {:noreply, assign(socket, selected_lists: new_selected_lists)}
  end

  def handle_event("confirm_add_to_lists", _params, socket) do
    if Enum.empty?(socket.assigns.selected_lists) do
      {:noreply, put_flash(socket, :error, "Please select at least one list")}
    else
      selected_problem_ids = MapSet.to_list(socket.assigns.selected_problems)

      results =
        Enum.map(socket.assigns.selected_lists, fn list_id ->
          Study.add_leetcode_problems_to_list(list_id, selected_problem_ids)
        end)

      case Enum.find(results, fn result -> match?({:error, _}, result) end) do
        nil ->
          total_added = Enum.sum(Enum.map(results, fn {:ok, count} -> count end))

          {:noreply,
           socket
           |> assign(selected_problems: MapSet.new())
           |> assign(show_list_modal: false)
           |> assign(selected_lists: [])
           |> put_flash(:info, "Successfully added #{total_added} problems to the selected lists")}

        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "Failed to add some problems: #{inspect(reason)}")}
      end
    end
  end

  def handle_event("show_create_list_modal", _params, socket) do
    {:noreply, assign(socket, show_create_list_modal: true)}
  end

  def handle_event("close_create_list_modal", _params, socket) do
    {:noreply, assign(socket, show_create_list_modal: false)}
  end

  def handle_event("create_list", %{"list" => list_params}, socket) do
    list_params = Map.put(list_params, "user_id", socket.assigns.current_user.id)

    case Study.create_list(list_params) do
      {:ok, _new_list} ->
        user_lists = Study.list_lists_for_user(socket.assigns.current_user.id)

        {:noreply,
         socket
         |> assign(user_lists: user_lists)
         |> assign(show_create_list_modal: false)
         |> assign(new_list_form: to_form(Study.change_list(%LeetcodeSpaced.Study.List{})))
         |> put_flash(:info, "List created successfully!")}

      {:error, changeset} ->
        {:noreply, assign(socket, new_list_form: to_form(changeset))}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100">
      <!-- Navigation -->
      <nav class="bg-base-100 shadow-sm border-b border-base-300">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex justify-between h-16">
            <div class="flex items-center space-x-4">
              <.link
                href="/"
                class="text-2xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent"
              >
                SpacedCode
              </.link>
              <span class="text-base-content/60">/</span>
              <span class="text-base-content/80">Problem Selection</span>
            </div>
            <div class="flex items-center space-x-4">
              <%= if @current_user do %>
                <div class="flex items-center space-x-3">
                  <%= if @current_user.avatar_url && @current_user.avatar_url != "" do %>
                    <img
                      src={@current_user.avatar_url}
                      alt={@current_user.name}
                      class="w-8 h-8 rounded-full border border-base-300"
                      referrerpolicy="no-referrer"
                    />
                  <% else %>
                    <div class="w-8 h-8 rounded-full bg-gradient-to-r from-blue-500 to-purple-500 flex items-center justify-center text-white font-semibold text-sm">
                      {String.first(@current_user.name || "U") |> String.upcase()}
                    </div>
                  <% end %>
                  <span class="text-base-content font-medium">{@current_user.name}</span>
                  <.link
                    href="/auth/logout"
                    class="bg-gradient-to-r from-red-500 to-red-600 hover:from-red-600 hover:to-red-700 text-white px-4 py-2 rounded-lg font-medium transition-all duration-200 shadow-sm hover:shadow-md"
                  >
                    Logout
                  </.link>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </nav>
      
    <!-- Main Content -->
      <div class="max-w-7xl mx-auto py-8 px-4 sm:px-6 lg:px-8">
        <!-- Header -->
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-base-content">Select Problems</h1>
          <p class="text-base-content/70 mt-2">Choose LeetCode problems to add to your lists</p>
        </div>
        
    <!-- Filters and Search -->
        <div class="bg-base-200 rounded-xl p-6 border border-base-300 mb-6">
          <div class="grid md:grid-cols-4 gap-4">
            <!-- Search -->
            <div>
              <label class="label">
                <span class="label-text font-medium">Search Problems</span>
              </label>
              <form phx-change="search" class="flex">
                <input
                  type="text"
                  name="search"
                  value={@search}
                  placeholder="Search by problem name..."
                  class="input input-bordered w-full"
                />
              </form>
            </div>
            
    <!-- Difficulty Filter -->
            <div>
              <label class="label">
                <span class="label-text font-medium">Difficulty</span>
              </label>
              <form phx-change="filter_difficulty">
                <select name="difficulty" class="select select-bordered w-full">
                  <option value="">All Difficulties</option>
                  <%= for difficulty <- @difficulties do %>
                    <option value={difficulty} selected={@selected_difficulty == difficulty}>
                      {difficulty}
                    </option>
                  <% end %>
                </select>
              </form>
            </div>
            
    <!-- Category Filter -->
            <div>
              <label class="label">
                <span class="label-text font-medium">Category</span>
              </label>
              <form phx-change="filter_category">
                <select name="category" class="select select-bordered w-full">
                  <option value="">All Categories</option>
                  <%= for category <- @categories do %>
                    <option value={category.name} selected={@selected_category == category.name}>
                      {category.name}
                    </option>
                  <% end %>
                </select>
              </form>
            </div>
            
    <!-- Selection Actions -->
            <div class="flex items-end space-x-2">
              <button
                type="button"
                phx-click="select_all"
                class="btn btn-sm btn-outline"
              >
                Select All
              </button>
              <button
                type="button"
                phx-click="deselect_all"
                class="btn btn-sm btn-outline"
              >
                Deselect All
              </button>
            </div>
          </div>
        </div>
        
    <!-- Selection Summary -->
        <%= if MapSet.size(@selected_problems) > 0 do %>
          <div class="bg-primary/10 border border-primary/20 rounded-lg p-4 mb-6">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-4">
                <span class="text-primary font-semibold">
                  {MapSet.size(@selected_problems)} problem{if MapSet.size(@selected_problems) == 1,
                    do: "",
                    else: "s"} selected
                </span>
                <button
                  type="button"
                  phx-click="add_to_list"
                  class="btn btn-primary btn-sm"
                >
                  Add to List
                </button>
              </div>
              <button
                type="button"
                phx-click="deselect_all"
                class="text-primary/70 hover:text-primary"
              >
                Clear Selection
              </button>
            </div>
          </div>
        <% end %>
        
    <!-- Problems Grid -->
        <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
          <%= for problem <- @problems do %>
            <div class={[
              "bg-base-200 rounded-xl p-4 border transition-all duration-200 cursor-pointer",
              if(MapSet.member?(@selected_problems, problem.leetcode_id),
                do: "border-primary bg-primary/5",
                else: "border-base-300 hover:border-base-400"
              )
            ]}>
              <div class="flex items-start space-x-3">
                <input
                  type="checkbox"
                  checked={MapSet.member?(@selected_problems, problem.leetcode_id)}
                  phx-click="toggle_problem"
                  phx-value-leetcode_id={problem.leetcode_id}
                  class="checkbox checkbox-sm mt-1"
                />
                <div class="flex-1 min-w-0">
                  <div class="flex items-center space-x-2 mb-2">
                    <h3 class="font-semibold text-base-content truncate">
                      {problem.name}
                    </h3>
                    <span class={[
                      "px-2 py-1 rounded-full text-xs font-medium flex-shrink-0",
                      case problem.difficulty do
                        "Easy" -> "bg-green-100 text-green-800"
                        "Medium" -> "bg-yellow-100 text-yellow-800"
                        "Hard" -> "bg-red-100 text-red-800"
                        _ -> "bg-gray-100 text-gray-800"
                      end
                    ]}>
                      {problem.difficulty}
                    </span>
                  </div>

                  <div class="text-sm text-base-content/60 mb-2">
                    #{problem.leetcode_id}
                  </div>

                  <%= if length(problem.categories) > 0 do %>
                    <div class="flex flex-wrap gap-1 mb-3">
                      <%= for category <- Enum.take(problem.categories, 3) do %>
                        <span class="px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded-full">
                          {category.name}
                        </span>
                      <% end %>
                      <%= if length(problem.categories) > 3 do %>
                        <span class="px-2 py-1 bg-gray-100 text-gray-600 text-xs rounded-full">
                          +{length(problem.categories) - 3}
                        </span>
                      <% end %>
                    </div>
                  <% end %>

                  <a
                    href={problem.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    class="text-primary hover:text-primary/80 text-sm inline-flex items-center"
                    onclick="event.stopPropagation()"
                  >
                    View on LeetCode
                    <svg class="w-3 h-3 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
                      />
                    </svg>
                  </a>
                </div>
              </div>
            </div>
          <% end %>
        </div>
        
    <!-- Load More Button -->
        <%= if @page < @total_pages do %>
          <div class="text-center mt-8">
            <button
              type="button"
              phx-click="load_more"
              class="btn btn-outline"
            >
              Load More Problems
            </button>
          </div>
        <% end %>
        
    <!-- Results Summary -->
        <div class="text-center mt-8 text-base-content/60">
          Showing {length(@problems)} of {@total_count} problems
        </div>
      </div>
      
    <!-- List Selection Modal -->
      <%= if @show_list_modal do %>
        <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div class="bg-base-100 rounded-xl p-6 max-w-md w-full mx-4">
            <h2 class="text-xl font-semibold text-base-content mb-4">
              Add to Lists
            </h2>
            <p class="text-base-content/70 mb-4">
              Select the lists you want to add {MapSet.size(@selected_problems)} problem{if MapSet.size(
                                                                                              @selected_problems
                                                                                            ) == 1,
                                                                                            do: "",
                                                                                            else: "s"} to:
            </p>

            <div class="space-y-3 mb-6 max-h-64 overflow-y-auto">
              <%= for list <- @user_lists do %>
                <label class="flex items-center space-x-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={list.id in @selected_lists}
                    phx-click="toggle_list_selection"
                    phx-value-list_id={list.id}
                    class="checkbox"
                  />
                  <div class="flex-1">
                    <div class="font-medium text-base-content">{list.name}</div>
                    <div class="text-sm text-base-content/60">{list.description}</div>
                  </div>
                </label>
              <% end %>
            </div>

            <div class="flex space-x-3">
              <button
                type="button"
                phx-click="confirm_add_to_lists"
                class="btn btn-primary flex-1"
              >
                Add to Selected Lists
              </button>
              <button
                type="button"
                phx-click="close_list_modal"
                class="btn btn-outline"
              >
                Cancel
              </button>
            </div>

            <div class="mt-4 text-center">
              <button
                type="button"
                phx-click="show_create_list_modal"
                class="text-primary hover:text-primary/80 text-sm"
              >
                Create New List
              </button>
            </div>
          </div>
        </div>
      <% end %>
      
    <!-- Create List Modal -->
      <%= if @show_create_list_modal do %>
        <div class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div class="bg-base-100 rounded-xl p-6 max-w-md w-full mx-4">
            <h2 class="text-xl font-semibold text-base-content mb-4">
              Create New List
            </h2>

            <.form for={@new_list_form} phx-submit="create_list" class="space-y-4">
              <.input
                field={@new_list_form[:name]}
                type="text"
                label="Name"
                placeholder="Enter list name..."
              />
              <.input
                field={@new_list_form[:description]}
                type="textarea"
                label="Description"
                placeholder="Enter list description..."
              />
              <.input
                field={@new_list_form[:is_public]}
                type="checkbox"
                label="Make this list public"
              />

              <div class="flex space-x-3">
                <button
                  type="submit"
                  class="btn btn-primary flex-1"
                >
                  Create List
                </button>
                <button
                  type="button"
                  phx-click="close_create_list_modal"
                  class="btn btn-outline"
                >
                  Cancel
                </button>
              </div>
            </.form>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
