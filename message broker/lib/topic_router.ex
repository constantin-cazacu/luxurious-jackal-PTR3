defmodule TopicRouter do
  use GenServer
  require Logger

  def start_link() do
    Logger.info("Starting Topic Router", ansi_color: :yellow)
    {:ok, message_storage} = :dets.open_file(:message_storage, [type: :duplicate_bag])
    state = %{topic_list: [], topic_worker_list: []}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def receive_message(message) do
    GenServer.call(__MODULE__, {:rcv_message, message})
  end

  def add_topic(topic, pid) do
    GenServer.cast(__MODULE__, {:add_topic, {topic, pid}})
  end
  
  def topic_list_request() do
    GenServer.call(__MODULE__, :topic_list_req)
  end

  def send_to_topic_worker(message, topic_list, topic_worker_list) do
    topic_to_match = message["topic"]
    matching_index = Enum.find_index(topic_list, fn topic -> topic === topic_to_match end)
    matching_topic_worker = Enum.at(topic_worker_list, matching_index)
    TopicWorker.receive_message(message, matching_topic_worker)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:rcv_message, message}, _from, state) do
    topic = message["topic"]
    data = message["message"]
    :dets.insert(:message_storage, {topic, data})
    topic_list = state.topic_list
    topic_worker_list = state.topic_worker_list
    if Enum.member?(topic_list, topic) do
#      Logger.info("Sending to topic worker", ansi_color: :blue)
      send_to_topic_worker(message, topic_list, topic_worker_list)
    else
#      Logger.info("Starting #{topic} worker", ansi_color: :yellow)
      new_topic_worker_pid = TopicSupervisor.create_worker(topic)
      TopicWorker.receive_message(message, new_topic_worker_pid)
    end
    {:reply, :next, state}
  end

  def handle_cast({:add_topic, {topic, pid}}, state) do
    topic_worker_list = state.topic_worker_list
    topic_list = state.topic_list
    new_topic_list = [topic | topic_list]
    new_topic_worker_list = [pid | topic_worker_list]
    {:noreply, %{state | topic_list: new_topic_list, topic_worker_list: new_topic_worker_list}}
  end

  def handle_call(:topic_list_req, _from, state) do
    Logger.info("[TOPIC ROUTER] Sending topic list", ansi_color: :magenta)
    topic_list = state.topic_list
    {:reply, topic_list, state}
  end

end
