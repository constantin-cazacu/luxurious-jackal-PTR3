defmodule Consumer do
  use GenServer
  require Logger

  def start_link() do
    state = %{pid: :empty, socket: :empty, subscribed_topics: []}
    Logger.info("Starting Consumer", ansi_color: :yellow)
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def connect(pid) do
    GenServer.cast(pid, :connect)
  end

  def subscribe(topic_list, pid) do
    GenServer.cast(pid, {:subscribe, topic_list})
  end

  def unsubscribe(socket) do
    {:ok, encoded_message} = Poison.encode(:unsubscribe_from_topic_command)
    :gen_tcp.send(socket, encoded_message)
  end

  def receive_message(socket) do
    {:ok, encoded_message} = :gen_tcp.recv(socket, 0)
    {:ok, message} = Poison.decode(encoded_message)
    topic = Map.get(message, "topic")
    Logger.info("[CONSUMER] received message: #{inspect(message)}", ansi_color: :magenta)
    pid = self()
    Logger.info("[CONSUMER] topic is #{inspect(topic)}")
    send_ack(pid, topic)
  end

  def send_ack(pid, topic) do
    Logger.info("[CONSUMER] i'm in ack, topic #{inspect(topic)}")
    GenServer.cast(pid, {:ack, topic})
  end

  def init(state) do
    pid = self()
    connect(pid)
    {:ok, %{state | pid: pid}}
  end

  def handle_cast(:connect, state) do
    pid = state.pid
    {:ok, socket} = :gen_tcp.connect('127.0.0.1', 8082, [:binary, active: false])
    Logger.info("received socket #{inspect(socket)}")
    message = %{message_type: :connect}
#    Logger.info("[CONSUMER] pre-encoding message: #{inspect(message)}", ansi_color: :light_magenta)
    {:ok, encoded_message} = Poison.encode(message)
#    Logger.info("[CONSUMER] encoded message: #{inspect(encoded_message)}", ansi_color: :light_yellow)
#    {:ok, decoded_message} = Poison.decode(encoded_message)
#    Logger.info("[CONSUMER] decoded message: #{inspect(decoded_message)}", ansi_color: :light_green)
    :gen_tcp.send(socket, "#{encoded_message}\n\r")
    {:ok, encoded_topic_list} = :gen_tcp.recv(socket, 0)
    {:ok, topic_list} = Poison.decode(encoded_topic_list)
#    Logger.info("[CONSUMER] Topic list: #{inspect(topic_list)}", ansi_color: :green)
    subscribe(topic_list, pid)
    {:noreply, %{state | socket: socket}}
  end

  def handle_cast({:subscribe, topic_list}, state) do
    socket = state.socket
    Logger.info("[CONSUMER] received socket #{inspect(socket)}")
    subscribed_topics = state.subscribed_topics
    chosen_topic = Enum.random(topic_list)
    Logger.info("[CONSUMER] chosen topic #{inspect(chosen_topic)}", ansi_color: :light_yellow)
    new_subscribed_topics = [chosen_topic | subscribed_topics]
    message = %{message_type: :subscribe, topic: chosen_topic}
    {:ok, encoded_message} = Poison.encode(message)
    :gen_tcp.send(socket, "#{encoded_message}\n\r")
    receive_message(socket)
    {:noreply, %{state | subscribed_topics: new_subscribed_topics}}
  end

  def handle_cast({:ack, topic}, state) do
    socket = state.socket
    message = %{message_type: :acknowledgement, topic: topic}
    Logger.info("[CONSUMER] ack handle cast message #{inspect(message)}")
    {:ok, encoded_message} = Poison.encode(message)
    Logger.info("[CONSUMER] encoded message #{inspect(encoded_message)}")
    :gen_tcp.send(socket, "#{encoded_message}\n\r")
    receive_message(socket)
    {:noreply, state}
  end
end
