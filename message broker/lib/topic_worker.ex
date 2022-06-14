defmodule TopicWorker do
  use GenServer
  require Logger

#  TODO add state
  def start_link(topic) do
    GenServer.start_link(__MODULE__, %{}, name: String.to_atom("#{topic}Worker"))
  end

  defp extract_topic(topic_worker_list) do
    
  end

  def receive_message(message, topic_worker_pid) do
    {topic_to_match, data} = message
    GenServer.cast(topic_worker_pid, {:message, message})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:message, message}, state) do
    Logger.info("message: #{inspect(message)}")
    {:noreply, state}
  end
end
