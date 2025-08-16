defmodule LeetcodeSpacedWeb.AuthController do
  use LeetcodeSpacedWeb, :controller
  plug Ueberauth

  alias LeetcodeSpaced.Accounts

  def request(conn, _params) do
    # Debug OAuth configuration
    oauth_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Google.OAuth)
    IO.inspect(oauth_config, label: "OAuth Config")

    client_id = System.get_env("GOOGLE_CLIENT_ID")
    client_secret = System.get_env("GOOGLE_CLIENT_SECRET")
    IO.inspect({client_id, client_secret}, label: "Environment Variables")

    # This will redirect to Google OAuth
    # Ueberauth handles this automatically
    render(conn, :request)
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    IO.inspect(auth, label: "Auth Data")
    IO.inspect(auth.info, label: "Auth Info")

    case create_or_update_user(auth) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Successfully authenticated.")
        |> put_session(:user_id, user.id)
        |> redirect(to: ~p"/")

      {:error, changeset} ->
        IO.inspect(changeset, label: "Changeset Error")

        conn
        |> put_flash(:error, "Authentication failed: Unable to create user account")
        |> redirect(to: ~p"/")
    end
  end

  def callback(conn, _params) do
    conn
    |> put_flash(:error, "Authentication failed.")
    |> redirect(to: ~p"/")
  end

  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "You have been logged out.")
    |> redirect(to: ~p"/")
  end

  defp create_or_update_user(%Ueberauth.Auth{} = auth) do
    # Handle missing name by using email prefix or a default
    name =
      auth.info.name ||
        auth.info.first_name ||
        (auth.info.email && String.split(auth.info.email, "@") |> hd()) ||
        "User"

    user_params = %{
      email: auth.info.email,
      name: name,
      google_id: auth.uid,
      avatar_url: auth.info.image
    }

    IO.inspect(user_params, label: "User Params")

    case Accounts.get_user_by_email(auth.info.email) do
      nil ->
        Accounts.create_user(user_params)

      user ->
        Accounts.update_user(user, user_params)
    end
  end
end
