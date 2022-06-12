defmodule BrokerConnector do
  use GenServer
  require Logger

  def start_link(port, collection_name) do
    Logger.info("Starting Broker Connector", ansi_color: :yellow)
    {:ok, mongo_pid} = Mongo.start_link(url: "mongodb://localhost:27017/TweetDataStream")
    {:ok, socket} = :gen_tcp.connect('broker', 8082)
    state = %{mongo_pid: mongo_pid, socket: socket, topic: collection_name}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def get_data() do
    GenServer.cast(__MODULE__, :get_data)
  end

  def send_message(topic, message) do
    GenServer.cast(__MODULE__, {:send_message, {topic, message}})
  end

  def init(state) do
    get_data()
    {:ok, state}
  end

  def handle_cast(:get_data, state) do
    mongo_pid = state.mongo_pid
    topic = state.topic
    cursor = Mongo.find(mongo_pid, topic, %{})
    message_list = Enum.to_list(cursor)
    Enum.each(message_list, fn message -> send_message(topic, message) end)
    {:noreply, state}
  end

  def handle_cast({:send_message, {topic, message}}, state) do
    socket = state.socket
    topic_object = %{topic: topic, message: message}
    {:ok, encoded_message} = Poison.encode(topic_object)
    :gen_tcp.send(socket, encoded_message)
    {:noreply, state}
  end
end
