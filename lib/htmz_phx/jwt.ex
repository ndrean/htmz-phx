defmodule JWT do
  @moduledoc """
  Simple JWT verification module matching the Zig implementation.
  """

  def verify_jwt(token) do
    case String.split(token, ".") do
      [header, payload, signature] ->
        signature_input = "#{header}.#{payload}"
        jwt_secret = Application.get_env(:htmz_phx, :jwt_secret, "secret_key_for_jwt")

        expected_signature =
          :crypto.mac(:hmac, :sha256, jwt_secret, signature_input)
          |> Base.encode64(padding: false)

        if signature == expected_signature do
          case Base.decode64(payload, padding: false) do
            {:ok, payload_json} ->
              case Jason.decode(payload_json) do
                {:ok, %{"user_id" => user_id, "exp" => exp}} ->
                  if exp > System.system_time(:second) do
                    {:ok, user_id}
                  else
                    {:error, :expired}
                  end

                _ ->
                  {:error, :invalid_payload}
              end

            _ ->
              {:error, :invalid_encoding}
          end
        else
          {:error, :invalid_signature}
        end

      _ ->
        {:error, :invalid_format}
    end
  end
end