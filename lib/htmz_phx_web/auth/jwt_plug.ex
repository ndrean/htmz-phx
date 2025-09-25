defmodule HtmzPhxWeb.Auth.JWTPlug do
  @moduledoc """
  JWT authentication plug matching the Zig implementation.
  Creates JWT tokens from random strings and validates them.
  """
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_jwt_from_cookie(conn) do
      {:ok, user_id, token} ->
        conn
        |> assign(:current_user_id, user_id)
        |> assign(:jwt_token, token)

      {:error, :missing} ->
        create_and_set_jwt(conn)

      {:error, :invalid} ->
        create_and_set_jwt(conn)
    end
  end

  def get_jwt_from_cookie(conn) do
    case conn.cookies["jwt_token"] do
      nil ->
        {:error, :missing}

      token ->
        case JWT.verify_jwt(token) do
          {:ok, user_id} -> {:ok, user_id, token}
          {:error, _} -> {:error, :invalid}
        end
    end
  end

  defp create_and_set_jwt(conn) do
    user_id = generate_user_id()
    token = create_jwt(user_id)

    conn
    |> put_resp_cookie("jwt_token", token,
      # 30 days
      max_age: 60 * 60 * 24 * 30,
      http_only: true,
      same_site: "Lax"
    )
    |> assign(:current_user_id, user_id)
    |> assign(:jwt_token, token)
  end

  defp generate_user_id do
    # Generate random user ID like in Zig version
    :crypto.strong_rand_bytes(16)
    |> Base.encode64(padding: false)
  end

  defp create_jwt(user_id) do
    # Simple JWT creation (matching Zig approach)
    header =
      %{"alg" => "HS256", "typ" => "JWT"} |> Jason.encode!() |> Base.encode64(padding: false)

    payload =
      %{"user_id" => user_id, "exp" => System.system_time(:second) + 60 * 60 * 24 * 30}
      |> Jason.encode!()
      |> Base.encode64(padding: false)

    signature_input = "#{header}.#{payload}"
    jwt_secret = Application.get_env(:htmz_phx, :jwt_secret, "secret_key_for_jwt")

    signature =
      :crypto.mac(:hmac, :sha256, jwt_secret, signature_input)
      |> Base.encode64(padding: false)

    "#{header}.#{payload}.#{signature}"
  end

  # def verify_jwt(token) do
  #   case String.split(token, ".") do
  #     [header, payload, signature] ->
  #       signature_input = "#{header}.#{payload}"
  #       jwt_secret = Application.get_env(:htmz_phx, :jwt_secret, "secret_key_for_jwt")

  #       expected_signature =
  #         :crypto.mac(:hmac, :sha256, jwt_secret, signature_input)
  #         |> Base.encode64(padding: false)

  #       if signature == expected_signature do
  #         case Base.decode64(payload, padding: false) do
  #           {:ok, payload_json} ->
  #             case Jason.decode(payload_json) do
  #               {:ok, %{"user_id" => user_id, "exp" => exp}} ->
  #                 if exp > System.system_time(:second) do
  #                   {:ok, user_id}
  #                 else
  #                   {:error, :expired}
  #                 end

  #               _ ->
  #                 {:error, :invalid_payload}
  #             end

  #           _ ->
  #             {:error, :invalid_encoding}
  #         end
  #       else
  #         {:error, :invalid_signature}
  #       end

  #     _ ->
  #       {:error, :invalid_format}
  #   end
  # end

  def require_auth(conn, _opts) do
    case conn.assigns[:current_user_id] do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> put_view(html: HtmzPhxWeb.ErrorHTML)
        |> render(:"401")
        |> halt()

      _ ->
        conn
    end
  end
end
