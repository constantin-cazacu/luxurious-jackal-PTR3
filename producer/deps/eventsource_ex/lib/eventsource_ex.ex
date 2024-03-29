defmodule EventsourceEx do
  use GenServer
  require Logger

  @spec new(String.t, Keyword.t) :: {:ok, pid}
  def new(url, opts \\ []) do
    parent = opts[:stream_to] || self()
    opts = Keyword.put(opts, :stream_to, parent)
    |> Keyword.put(:url, url)

    GenServer.start_link(__MODULE__, opts, opts)
  end

  defp parse_options(opts) do
    url = opts[:url]
    headers = opts[:headers] || []
    parent = opts[:stream_to]
    follow_redirect = opts[:follow_redirect]
    hackney_opts = opts[:hackney]
    ssl = opts[:ssl]
    adapter = opts[:adapter] || HTTPoison
    http_options = [stream_to: self(), ssl: ssl, follow_redirect: follow_redirect,
                                  hackney: hackney_opts, recv_timeout: :infinity]

    {url, headers, parent, adapter, Enum.filter(http_options, fn({_,val}) -> val != nil end)}
  end

  def init(opts \\ []) do
    {url, headers, parent, adapter, options} = parse_options(opts)
    Logger.debug(fn -> "starting stream with http options: #{inspect options}" end)
    adapter.get!(url, headers, options)

    {:ok, %{parent: parent, message: %EventsourceEx.Message{}, prev_chunk: nil}}
  end

  def handle_info(%{chunk: data}, %{parent: parent, message: message, prev_chunk: prev_chunk}) do
    data = if prev_chunk, do: prev_chunk <> data, else: data

    if String.ends_with?(data, "\n") do
      data = String.split(data, "\n")

      message = parse_stream(data, parent, message)

      {:noreply, %{parent: parent, message: message, prev_chunk: nil}}
    else
      # Chunk didn't end with newline - assume data was cut and append next chunk
      {:noreply, %{parent: parent, message: message, prev_chunk: data}}
    end
  end

  def handle_info(%HTTPoison.AsyncEnd{}, state) do
    {:stop, :connection_terminated, state}
  end

  def handle_info(_msg, state) do
    # Ignore unhandled messages
    {:noreply, state}
  end

  defp parse_stream(["" | data], parent, message) do
    if message.data, do: dispatch(parent, message)
    parse_stream(data, parent, %EventsourceEx.Message{})
  end
  defp parse_stream([line | data], parent, message) do
    message = parse(line, message)
    parse_stream(data, parent, message)
  end
  defp parse_stream([], _, message), do: message

  defp parse(raw_line, message) do
    case raw_line do
      ":" <> _ -> message
      line ->
        splits = String.split(line, ":", parts: 2)
        [field | rest] = splits
        value = Enum.join(rest, "") |> String.replace_prefix(" ", "") # Remove single leading space

        case field do
          "event" -> Map.put(message, :event, value)
          "data" ->
            data = message.data || ""
            Map.put(message, :data, data <> value <> "\n")
          "id" -> Map.put(message, :id, value)
          _ -> message
        end
    end
  end

  defp dispatch(parent, message) do
    message = Map.put(message, :data, message.data |> String.replace_suffix("\n", "")) # Remove single trailing \n from message.data if necessary
    |> Map.put(:dispatch_ts, DateTime.utc_now) # Add dispatch timestamp

    send(parent, message)
  end
end
