defmodule LeetcodeSpacedWeb.ListsLive do
  use LeetcodeSpacedWeb, :live_view
  import LeetcodeSpacedWeb.Layouts, only: [navbar: 1]
  
  alias LeetcodeSpaced.Study
  alias LeetcodeSpaced.Study.List

  def mount(_params, session, socket) do
    current_user = get_current_user(session)

    if current_user do
      lists = Study.list_lists_for_user(current_user.id)

      socket =
        socket
        |> assign(current_user: current_user)
        |> assign(lists: lists)
        |> assign(show_form: false)
        |> assign(form: to_form(Study.change_list(%List{})))

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

  def handle_event("toggle_form", _params, socket) do
    {:noreply, assign(socket, show_form: !socket.assigns.show_form)}
  end

  def handle_event("create_list", %{"list" => list_params}, socket) do
    list_params = Map.put(list_params, "user_id", socket.assigns.current_user.id)

    case Study.create_list(list_params) do
      {:ok, _list} ->
        lists = Study.list_lists_for_user(socket.assigns.current_user.id)

        socket =
          socket
          |> assign(lists: lists)
          |> assign(show_form: false)
          |> assign(form: to_form(Study.change_list(%List{})))
          |> put_flash(:info, "List created successfully!")

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("delete_list", %{"id" => id}, socket) do
    list = Study.get_list!(id)

    case Study.delete_list(list) do
      {:ok, _list} ->
        lists = Study.list_lists_for_user(socket.assigns.current_user.id)

        socket =
          socket
          |> assign(lists: lists)
          |> put_flash(:info, "List deleted successfully!")

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete list")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100">
      <.navbar current_user={@current_user} />
      
      <!-- Main Content -->
      <div class="max-w-7xl mx-auto py-8 px-4 sm:px-6 lg:px-8">
        <!-- Header -->
        <div class="mb-8 flex items-center justify-between">
          <div>
            <h1 class="text-3xl font-bold text-base-content">Problem Lists</h1>
            <p class="text-base-content/70 mt-2">
              Organize your coding practice with custom problem lists
            </p>
          </div>
          <div class="flex space-x-3">
            <.link
              href="/problems"
              class="inline-flex items-center bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 text-white px-6 py-3 rounded-xl font-semibold shadow-lg hover:shadow-xl transition-all duration-200"
            >
              <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 8l2 2 4-4"
                />
              </svg>
              Add Problems
            </.link>
            <button
              type="button"
              phx-click="toggle_form"
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
              New List
            </button>
          </div>
        </div>
        
    <!-- Create List Form -->
        <%= if @show_form do %>
          <div class="mb-8 bg-base-200 rounded-xl p-6 border border-base-300">
            <h2 class="text-xl font-semibold text-base-content mb-4">Create New List</h2>
            <.form for={@form} phx-submit="create_list" class="space-y-4">
              <.input field={@form[:name]} type="text" label="Name" placeholder="Enter list name..." />
              <.input
                field={@form[:description]}
                type="textarea"
                label="Description"
                placeholder="Enter list description..."
              />
              <.input field={@form[:is_public]} type="checkbox" label="Make this list public" />
              <div class="flex space-x-3">
                <button
                  type="submit"
                  class="bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 text-white px-4 py-2 rounded-lg font-medium transition-all duration-200"
                >
                  Create List
                </button>
                <button
                  type="button"
                  phx-click="toggle_form"
                  class="bg-base-300 hover:bg-base-400 text-base-content px-4 py-2 rounded-lg font-medium transition-all duration-200"
                >
                  Cancel
                </button>
              </div>
            </.form>
          </div>
        <% end %>
        
    <!-- Lists Grid -->
        <%= if Enum.empty?(@lists) do %>
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
                d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"
              />
            </svg>
            <h3 class="text-xl font-semibold text-base-content/60 mb-2">No lists yet</h3>
            <p class="text-base-content/50 mb-6">Create your first problem list to get started</p>
            <div class="flex space-x-3">
              <.link
                href="/problems"
                class="inline-flex items-center bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 text-white px-6 py-3 rounded-xl font-semibold shadow-lg hover:shadow-xl transition-all duration-200"
              >
                <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 8l2 2 4-4"
                  />
                </svg>
                Add Problems
              </.link>
              <button
                type="button"
                phx-click="toggle_form"
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
                Create Your First List
              </button>
            </div>
          </div>
        <% else %>
          <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            <%= for list <- @lists do %>
              <div class="bg-base-200 rounded-xl p-6 border border-base-300 hover:shadow-lg transition-all duration-200 group">
                <div class="flex items-start justify-between mb-4">
                  <div class="flex-1">
                    <h3 class="text-xl font-semibold text-base-content group-hover:text-primary transition-colors duration-200">
                      {list.name}
                    </h3>
                    <%= if list.is_public do %>
                      <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 mt-2">
                        <svg
                          class="w-3 h-3 mr-1"
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24"
                        >
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
                  <button
                    type="button"
                    phx-click="delete_list"
                    phx-value-id={list.id}
                    data-confirm="Are you sure you want to delete this list?"
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

                <p class="text-base-content/70 mb-6">
                  {list.description}
                </p>

                <div class="flex items-center justify-between">
                  <div class="flex items-center text-base-content/60 text-sm">
                    <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 8l2 2 4-4"
                      />
                    </svg>
                    {list.problem_count} {if list.problem_count == 1, do: "problem", else: "problems"}
                  </div>
                  <.link
                    navigate={"/lists/#{list.id}"}
                    class="inline-flex items-center text-primary hover:text-primary/80 font-medium transition-colors duration-200"
                  >
                    View Details
                    <svg class="w-4 h-4 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 5l7 7-7 7"
                      />
                    </svg>
                  </.link>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
