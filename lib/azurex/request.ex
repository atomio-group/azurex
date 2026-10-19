defmodule Azurex.Request do
  @moduledoc false

  @max_attempts 3
  @base_delay_ms 200

  @type request_opts :: [retry: boolean()]

  @doc """
  Sends the request, retrying on connection errors, 429 and 5xx responses.

  Pass `retry: false` for operations that are not safe to repeat when the
  response is lost, such as creating a container or deleting a blob.
  """
  @spec request(HTTPoison.Request.t(), request_opts()) ::
          {:ok,
           HTTPoison.Response.t() | HTTPoison.AsyncResponse.t() | HTTPoison.MaybeRedirect.t()}
          | {:error, HTTPoison.Error.t()}
  def request(request, opts \\ []) do
    if Keyword.get(opts, :retry, true) do
      request_with_retry(request, 1)
    else
      HTTPoison.request(request)
    end
  end

  defp request_with_retry(request, attempt) do
    result = HTTPoison.request(request)

    if retryable?(result) and attempt < @max_attempts do
      Process.sleep(@base_delay_ms * Integer.pow(2, attempt - 1))
      request_with_retry(request, attempt + 1)
    else
      result
    end
  end

  defp retryable?({:error, %HTTPoison.Error{}}), do: true

  defp retryable?({:ok, %HTTPoison.Response{status_code: status}}),
    do: status == 429 or status >= 500

  defp retryable?(_result), do: false
end
