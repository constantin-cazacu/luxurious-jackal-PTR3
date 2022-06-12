defmodule TopicWorker do
  use GenServer
  require Logger

  def start_link(topic) do
    GenServer.start_link(__MODULE__, %{}, name: String.to_atom("#{topic}Worker"))
  end

  def init(state) do
    {:ok, state}
  end

#  def handle_cast({:message, message}, state) do
#    Logger.info("message: #{inspect(message)}")
#    {:noreply, state}
  end
end
