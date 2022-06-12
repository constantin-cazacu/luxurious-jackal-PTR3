defmodule TopicRouter do
  use GenServer
  require Logger

  def start_link() do
    Logger.info("Starting Topic Router", ansi_color: :yellow)
    state = %{topic_list: [], topic_worker_list: []}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def receive_message(message) do
    GenServer.cast(__MODULE__, {:rcv_message, message})
  end

  def add_topic(topic, pid) do
    GenServer.cast(__MODULE__, {:add_topic, {topic, pid}})
  end

  def init(state) do
    {:ok, state}
  end

# TODO add sending to topic worker functionality
  def handle_cast({:rcv_message, message}, state) do
    {topic, data} = message
    topic_list = state.topic_list
    topic_worker_list = state.topic_worker_list
    if Enum.member?(topic_list, topic) do
      send_to_topic_worker(message)
    else
      TopicSupervisor.create_worker(topic)
    end
    {:noreply, state}
  end

  def handle_cast(:add_topic, {topic, pid}, state) do
    topic_worker_list = state.topic_worker_list
    topic_list = state.topic_list
    new_topic_worker_list = [{topic, pid} | topic_worker_list]
    new_topic_list = [topic | topic_list]
    {:noreply, %{state | topic_list: new_topic_list, topic_worker_list: new_topic_worker_list}}
  end

end
