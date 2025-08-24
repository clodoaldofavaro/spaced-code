defmodule LeetcodeSpacedWeb.ListDetailsLive do
  use LeetcodeSpacedWeb, :live_view
  alias LeetcodeSpaced.Study
  alias LeetcodeSpaced.Reviews

  def mount(%{"id" => list_id}, session, socket) do
    current_user = get_current_user(session)

    if current_user do
      list_id_int = String.to_integer(list_id)
      list = Study.get_list!(list_id_int)
      problems = Study.get_problems_for_list(list_id_int)
      due_problems = Reviews.get_due_problems_for_list(list_id_int, current_user.id)

      socket =
        socket
        |> assign(current_user: current_user)
        |> assign(list: list)
        |> assign(list_id: list_id_int)
        |> assign(problems: problems)
        |> assign(due_problems: due_problems)
        |> assign(show_all: false)
        |> assign(recently_solved: [])

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

  def handle_event("toggle_view", _params, socket) do
    {:noreply, assign(socket, show_all: !socket.assigns.show_all)}
  end

  def handle_event("remove_problem", %{"problem_id" => problem_id}, socket) do
    problem_id_int = String.to_integer(problem_id)

    case Study.remove_problem_from_list(socket.assigns.list_id, problem_id_int) do
      {:ok, _} ->
        problems = Study.get_problems_for_list(socket.assigns.list_id)

        due_problems =
          Reviews.get_due_problems_for_list(
            socket.assigns.list_id,
            socket.assigns.current_user.id
          )

        socket =
          socket
          |> assign(problems: problems)
          |> assign(due_problems: due_problems)
          |> put_flash(:info, "Problem removed from list!")

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to remove problem from list")}
    end
  end

  def handle_event("mark_solved", %{"problem_id" => problem_id, "rating" => rating}, socket) do
    require Logger
    Logger.info("=== REVIEW EVENT START ===")
    Logger.info("Problem ID: #{problem_id}, Rating: #{rating}")

    # Validate FSRS rating
    if rating == "" or is_nil(rating) do
      Logger.error("Invalid rating: empty or nil")
      {:noreply, put_flash(socket, :error, "Please select how you did first")}
    else
      problem_id_int = String.to_integer(problem_id)
      rating_atom = String.to_atom(rating)

      Logger.info(
        "Calling mark_problem_solved with: problem_id=#{problem_id_int}, user_id=#{socket.assigns.current_user.id}, rating=#{rating_atom}"
      )

      case Reviews.mark_problem_solved(
             problem_id_int,
             socket.assigns.current_user.id,
             rating_atom
           ) do
        {:ok, result} ->
          Logger.info("Review successful: #{inspect(result)}")
          # Add to recently solved for temporary green state
          recently_solved = [problem_id_int | socket.assigns.recently_solved]

          # Refresh both problems and due problems
          problems = Study.get_problems_for_list(socket.assigns.list_id)

          due_problems =
            Reviews.get_due_problems_for_list(
              socket.assigns.list_id,
              socket.assigns.current_user.id
            )

          Logger.info(
            "Refreshed data - problems: #{length(problems)}, due_problems: #{length(due_problems)}"
          )

          socket =
            socket
            |> assign(problems: problems)
            |> assign(due_problems: due_problems)
            |> assign(recently_solved: recently_solved)
            |> put_flash(:info, "Problem reviewed! 🎉")

          # Clear recently solved after 3 seconds
          Process.send_after(self(), {:clear_recently_solved, problem_id_int}, 3000)

          Logger.info("=== REVIEW EVENT SUCCESS ===")
          {:noreply, socket}

        {:error, reason} ->
          Logger.error("Review failed: #{inspect(reason)}")
          {:noreply, put_flash(socket, :error, "Failed to review problem: #{inspect(reason)}")}
      end
    end
  end

  def handle_info({:clear_recently_solved, problem_id}, socket) do
    recently_solved = List.delete(socket.assigns.recently_solved, problem_id)
    {:noreply, assign(socket, recently_solved: recently_solved)}
  end

  defp displayed_problems(assigns) do
    if assigns.show_all do
      assigns.problems
    else
      assigns.due_problems
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
              <.link href="/lists" class="text-base-content/80 hover:text-base-content">Lists</.link>
              <span class="text-base-content/60">/</span>
              <span class="text-base-content">{@list.name}</span>
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
          <div class="flex items-start justify-between mb-4">
            <div>
              <h1 class="text-3xl font-bold text-base-content">{@list.name}</h1>
              <p class="text-base-content/70 mt-2">{@list.description}</p>
              <%= if @list.is_public do %>
                <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 mt-2">
                  <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                  Public
                </span>
              <% end %>
            </div>
            <.link
              href="/problems"
              class="inline-flex items-center bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700 text-white px-6 py-3 rounded-xl font-semibold shadow-lg hover:shadow-xl transition-all duration-200"
            >
              <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                />
              </svg>
              Add Problem
            </.link>
          </div>
          
    <!-- Stats -->
          <div class="grid md:grid-cols-3 gap-4 mb-6">
            <div class="bg-base-200 rounded-lg p-4 border border-base-300">
              <div class="flex items-center">
                <div class="bg-blue-100 rounded-lg p-2 mr-3">
                  <svg
                    class="w-6 h-6 text-blue-600"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 8l2 2 4-4"
                    />
                  </svg>
                </div>
                <div>
                  <p class="text-2xl font-semibold text-base-content">{length(@problems)}</p>
                  <p class="text-base-content/60">Total Problems</p>
                </div>
              </div>
            </div>

            <div class="bg-base-200 rounded-lg p-4 border border-base-300">
              <div class="flex items-center">
                <div class="bg-orange-100 rounded-lg p-2 mr-3">
                  <svg
                    class="w-6 h-6 text-orange-600"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                </div>
                <div>
                  <p class="text-2xl font-semibold text-base-content">{length(@due_problems)}</p>
                  <p class="text-base-content/60">Due Today</p>
                </div>
              </div>
            </div>

            <div class="bg-base-200 rounded-lg p-4 border border-base-300">
              <div class="flex items-center">
                <div class="bg-green-100 rounded-lg p-2 mr-3">
                  <svg
                    class="w-6 h-6 text-green-600"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                </div>
                <div>
                  <p class="text-2xl font-semibold text-base-content">
                    {length(@problems) - length(@due_problems)}
                  </p>
                  <p class="text-base-content/60">Completed</p>
                </div>
              </div>
            </div>
          </div>
          
    <!-- View Toggle -->
          <div class="flex items-center space-x-4">
            <button
              type="button"
              phx-click="toggle_view"
              class={[
                "px-4 py-2 rounded-lg font-medium transition-all duration-200",
                if(@show_all,
                  do: "bg-base-300 text-base-content",
                  else: "bg-gradient-to-r from-orange-500 to-orange-600 text-white"
                )
              ]}
            >
              <%= if @show_all do %>
                Show All Problems ({length(@problems)})
              <% else %>
                Due Today ({length(@due_problems)})
              <% end %>
            </button>
            <span class="text-base-content/60 text-sm">
              {if @show_all, do: "Showing all problems", else: "Showing problems due for review today"}
            </span>
          </div>
        </div>
        
    <!-- Problems List -->
        <div class="space-y-4">
          <%= for problem <- displayed_problems(assigns) do %>
            <div class="bg-base-200 rounded-xl p-6 border border-base-300 hover:shadow-lg transition-all duration-200">
              <div class="flex items-start justify-between">
                <div class="flex-1">
                  <div class="flex items-center space-x-3 mb-3">
                    <h3 class="text-xl font-semibold text-base-content">{problem.title}</h3>
                    <span class={[
                      "px-2 py-1 rounded-full text-xs font-medium",
                      case problem.difficulty do
                        "Easy" -> "bg-green-100 text-green-800"
                        "Medium" -> "bg-yellow-100 text-yellow-800"
                        "Hard" -> "bg-red-100 text-red-800"
                        _ -> "bg-gray-100 text-gray-800"
                      end
                    ]}>
                      {problem.difficulty}
                    </span>
                    <span class="text-base-content/60 text-sm">#{problem.old_leetcode_id}</span>
                  </div>

                  <%= if problem.topics && length(problem.topics) > 0 do %>
                    <div class="flex flex-wrap gap-2 mb-4">
                      <%= for topic <- problem.topics do %>
                        <span class="px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded-full">
                          {topic}
                        </span>
                      <% end %>
                    </div>
                  <% end %>
                </div>

                <div class="flex items-center space-x-2">
                  <!-- Mark as Solved with Confidence -->
                  <%= if problem.id in @recently_solved do %>
                    <div class="flex items-center space-x-2">
                      <div class="bg-green-100 text-green-800 px-3 py-2 rounded-lg font-medium text-sm">
                        ✅ Reviewed!
                      </div>
                    </div>
                  <% else %>
                    <form phx-submit="mark_solved" class="flex items-center space-x-2">
                      <input type="hidden" name="problem_id" value={problem.id} />
                      <select
                        name="rating"
                        required
                        class="select select-sm bg-base-100 border-base-300 min-w-[160px]"
                      >
                        <option value="">How did you do?</option>
                        <option value="again">❌ Again - I forgot</option>
                        <option value="hard">😰 Hard - Difficult to recall</option>
                        <option value="good">😊 Good - I remembered</option>
                        <option value="easy">🚀 Easy - Very easy</option>
                      </select>
                      <button
                        type="submit"
                        class="bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 disabled:from-gray-400 disabled:to-gray-500 text-white px-3 py-2 rounded-lg font-medium transition-all duration-200 text-sm whitespace-nowrap"
                      >
                        📝 Review
                      </button>
                    </form>
                  <% end %>
                  
    <!-- Open in LeetCode -->
                  <a
                    href={problem.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    class="bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 text-white px-3 py-1 rounded-lg font-medium transition-all duration-200 text-sm inline-flex items-center"
                  >
                    <svg class="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
                      />
                    </svg>
                    Solve
                  </a>
                  
    <!-- Remove from List -->
                  <button
                    type="button"
                    phx-click="remove_problem"
                    phx-value-problem_id={problem.id}
                    data-confirm="Are you sure you want to remove this problem from the list?"
                    class="text-base-content/40 hover:text-red-500 transition-colors duration-200"
                  >
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                      />
                    </svg>
                  </button>
                </div>
              </div>
            </div>
          <% end %>

          <%= if Enum.empty?(displayed_problems(assigns)) do %>
            <div class="text-center py-12">
              <svg
                class="w-20 h-20 text-base-content/30 mx-auto mb-4"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 8l2 2 4-4"
                />
              </svg>
              <h3 class="text-xl font-semibold text-base-content/60 mb-2">
                <%= if @show_all do %>
                  No problems in this list
                <% else %>
                  No problems due today
                <% end %>
              </h3>
              <p class="text-base-content/50 mb-6">
                <%= if @show_all do %>
                  Add some problems to get started
                <% else %>
                  Great job! Check back tomorrow or view all problems
                <% end %>
              </p>
              <%= if @show_all do %>
                <.link
                  href="/problems"
                  class="inline-flex items-center bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 text-white px-6 py-3 rounded-xl font-semibold shadow-lg hover:shadow-xl transition-all duration-200"
                >
                  <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                    />
                  </svg>
                  Add Your First Problem
                </.link>
              <% else %>
                <button
                  type="button"
                  phx-click="toggle_view"
                  class="inline-flex items-center bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 text-white px-6 py-3 rounded-xl font-semibold shadow-lg hover:shadow-xl transition-all duration-200"
                >
                  <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"
                    />
                  </svg>
                  View All Problems
                </button>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
