defmodule LeetcodeSpacedWeb.PageController do
  use LeetcodeSpacedWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
