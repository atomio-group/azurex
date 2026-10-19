defmodule Azurex.Request do
  @moduledoc false

  @max_attempts 3
  @base_delay_ms 200

  @spec request(HTTPoison.Request.t()) ::
          {:ok,
           HTTPoison.Response.t() | HTTPoison.AsyncResponse.t() | HTTPoison.MaybeRedirect.t()}
          | {:error, HTTPoison.Error.t()}
  def request(request, attempt \\ 1) do
    result = HTTPoison.request(request)

    if retryable?(result) and attempt < @max_attempts do
      Process.sleep(@base_delay_ms * 2 ** (attempt - 1))
      request(request, attempt + 1)
    else
      result
    end
  end

  defp retryable?({:error, %HTTPoison.Error{}}), do: true

  defp retryable?({:ok, %HTTPoison.Response{status_code: status}}),
    do: status == 429 or status >= 500

  defp retryable?(_result), do: false
end
