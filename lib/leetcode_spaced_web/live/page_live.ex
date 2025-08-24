defmodule LeetcodeSpacedWeb.PageLive do
  use LeetcodeSpacedWeb, :live_view
  import LeetcodeSpacedWeb.Layouts, only: [navbar: 1]

  def mount(_params, session, socket) do
    current_user = get_current_user(session)

    socket =
      socket
      # Start with system, will be updated by JS
      |> assign(current_theme: "system")
      |> assign(current_user: current_user)

    {:ok, socket}
  end

  defp get_current_user(session) do
    case session["user_id"] do
      nil ->
        nil

      user_id ->
        user = LeetcodeSpaced.Accounts.get_user!(user_id)
        IO.inspect(user, label: "Current User from DB")
        user
    end
  rescue
    _ -> nil
  end

  def handle_event("toggle_theme", _params, socket) do
    new_theme = if socket.assigns.current_theme == "light", do: "dark", else: "light"

    socket =
      socket
      |> assign(current_theme: new_theme)
      |> push_event("theme-changed", %{theme: new_theme})

    {:noreply, socket}
  end

  def handle_event("sync_theme", %{"theme" => theme}, socket) do
    {:noreply, assign(socket, current_theme: theme)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-100">
      <.navbar current_user={@current_user} />
      
      <!-- Hero Section -->
      <div class="bg-gradient-to-b from-base-200 to-base-100 py-16">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <%= if @current_user do %>
            <h2 class="text-5xl font-bold mb-4">
              <span class="text-base-content">Welcome back, </span>
              <span class="bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
                {@current_user.name}!
              </span>
            </h2>
            <p class="text-xl text-base-content/70 mb-8">
              Ready to continue your coding journey? Let's practice some algorithms!
            </p>
            <div class="flex justify-center space-x-4">
              <.link
                navigate="/lists"
                class="inline-flex items-center bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700 text-white text-lg px-8 py-4 rounded-xl font-semibold shadow-lg hover:shadow-xl transition-all duration-200"
              >
                <svg class="w-6 h-6 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 6v6m0 0v6m0-6h6m-6 0H6"
                  />
                </svg>
                Start Practicing
              </.link>
              <button class="inline-flex items-center bg-gradient-to-r from-purple-500 to-purple-600 hover:from-purple-600 hover:to-purple-700 text-white text-lg px-8 py-4 rounded-xl font-semibold shadow-lg hover:shadow-xl transition-all duration-200">
                <svg class="w-6 h-6 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
                  />
                </svg>
                View Progress
              </button>
            </div>
          <% else %>
            <h2 class="text-5xl font-bold mb-4">
              <span class="bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
                Master Algorithms
              </span>
              <span class="text-base-content"> with </span>
              <span class="bg-gradient-to-r from-purple-600 to-pink-600 bg-clip-text text-transparent">
                Spaced Repetition
              </span>
            </h2>
            <p class="text-xl text-base-content/70 mb-8">
              Track your LeetCode progress, review problems at optimal intervals, and ace your coding interviews
            </p>
            <.link
              href="/auth/google"
              class="inline-flex items-center bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 text-white text-lg px-8 py-4 rounded-xl font-semibold shadow-lg hover:shadow-xl transition-all duration-200"
            >
              <svg class="w-6 h-6 mr-2" viewBox="0 0 24 24">
                <path
                  fill="currentColor"
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                />
                <path
                  fill="currentColor"
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                />
                <path
                  fill="currentColor"
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                />
                <path
                  fill="currentColor"
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                />
              </svg>
              Get Started with Google
            </.link>
          <% end %>
        </div>
      </div>
      
    <!-- Features -->
      <div class="py-16 bg-base-100">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div class="grid md:grid-cols-3 gap-8">
            <div class="text-center group">
              <div class="bg-gradient-to-br from-blue-100 to-blue-200 w-20 h-20 rounded-2xl flex items-center justify-center mx-auto mb-4 group-hover:scale-110 transition-transform duration-200 shadow-lg">
                <svg
                  class="w-10 h-10 text-blue-600"
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
              </div>
              <h3 class="text-xl font-bold text-base-content mb-2">Organize Problems</h3>
              <p class="text-base-content/70">
                Create custom lists and organize problems by topic, difficulty, or interview prep
              </p>
            </div>

            <div class="text-center group">
              <div class="bg-gradient-to-br from-green-100 to-green-200 w-20 h-20 rounded-2xl flex items-center justify-center mx-auto mb-4 group-hover:scale-110 transition-transform duration-200 shadow-lg">
                <svg
                  class="w-10 h-10 text-green-600"
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
              <h3 class="text-xl font-bold text-base-content mb-2">Spaced Repetition</h3>
              <p class="text-base-content/70">
                Review problems at scientifically optimal intervals to maximize retention
              </p>
            </div>

            <div class="text-center group">
              <div class="bg-gradient-to-br from-purple-100 to-purple-200 w-20 h-20 rounded-2xl flex items-center justify-center mx-auto mb-4 group-hover:scale-110 transition-transform duration-200 shadow-lg">
                <svg
                  class="w-10 h-10 text-purple-600"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
                  />
                </svg>
              </div>
              <h3 class="text-xl font-bold text-base-content mb-2">Track Progress</h3>
              <p class="text-base-content/70">
                Visualize your improvement and identify weak areas to focus on
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
