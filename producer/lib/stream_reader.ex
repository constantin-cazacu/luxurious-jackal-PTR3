defmodule StreamReader do
  @moduledoc """
  Stream Reader - an actor that reads the SSE streams and forwards information
  """
  require Logger

  def start_link(url) do
    Logger.info("Starting Stream Reader", ansi_color: :yellow)
    Logger.info(url)
    #    spawns get_tweet function from the given module,
    #    links it to current process
    handle = spawn_link(__MODULE__, :get_tweet, [])
    {:ok, pid} = EventsourceEx.new(url, stream_to: handle)
    #    spawns check_connection function from the given module,
    #    links it to current process
    spawn_link(__MODULE__, :check_connection, [url, handle, pid])
    {:ok, self()}
  end

  def get_tweet() do
    receive do
      tweet ->
#         sends tweet data to Router
        Router.receive_tweet(tweet.data)
    end
    get_tweet()
  end

  @doc"""
  starts monitoring the PID
  """
  def check_connection(url, handle, pid) do
    Process.monitor(pid)
    receive do
      _err ->
        IO.puts("restarting")
        {:ok, new_pid} = EventsourceEx.new(url, stream_to: handle)
        spawn_link(__MODULE__, :check_connection, [url, handle, new_pid])
    end
    :ok
  end
end
