defmodule Consumer do
  use GenServer
  require Logger
#  TODO Consumer workflow
'''
  I. How the consumer should connect & subscribe?
    1. Consumer connects to TCP Conn Supervisor, redirected to a tcp worker -> connection established
    2. Consumer receives a list of current topics from Topic Router (TCP Conn Worker shall request it
       once the connection is established)
    3. Consumer chooses at random one of the topics
    4. Consumer sends a message with the :subscribe keyword, chosen topic and index of message to be
       use in queue as arguments
    5. Consumer shall receive an ack

  II. Sending & Receiving
  *** Gotta think how to notify about new subscribe and how sending the messages should work *** (NOT FINALIZED)
    1. once the subscription ack has been received the Consumer shall send to the TCP Conn Worker request for message
    2. the selected Topic Worker (based on the subscribed topic from the previous section) shall receive
       a request for a message from the TCP Conn Worker (:message_request, topic, last_index)
    3. Topic Worker shall increment the index and select the message from the queue at the current
       index and send it to the TCP Conn worker which shall send it as a response to the Consumer
    4. Consumer shall receive the message with the index which shall be used to the follow-up request (will be treated
       as ack by message broker)
    5. repeat of the steps 2-4
'''
  def start_link() do
    state = %{pid: :empty, socket: :empty, subscribed_topics: []}
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
    topic = Map.get(message, :topic)
    Logger.info("Consumer: received message: #{inspect(String.slice(message, 0..50))}", ansi_color: :magenta)
    pid = self()
    send_ack(pid, topic)
  end

  def send_ack(pid, topic) do
    GenServer.cast(pid, {:ack, topic})
  end

  def init(state) do
    pid = self()
    connect(pid)
    {:ok, %{state | pid: pid}}
  end

  def handle_cast(:connect, state) do
    pid = state.pid
    {:ok, socket} = :gen_tcp.connect('127.0.0.1', 8082, [])
    message = %{message_type: :connect}
    {:ok, encoded_message} = Poison.encode(message)
    :gen_tcp.send(socket, encoded_message)
    {:ok, encoded_topic_list} = :gen_tcp.recv(socket, 0)
    {:ok, topic_list} = Poison.decode(encoded_topic_list)
    subscribe(topic_list, pid)
    {:norepley, %{state | socket: socket}}
  end

  def handle_cast({:subscribe, topic_list}, state) do
    socket = state.socket
    subscribed_topics = state.subscribed_topics
    chosen_topic = Enum.random(topic_list)
    new_subscribed_topics = [chosen_topic | subscribed_topics]
    message = %{message_type: :subscribe, topic: chosen_topic}
    {:ok, encoded_message} = Poison.encode(message)
    :gen_tcp.send(socket, encoded_message)
    receive_message(socket)
    {:noreply, %{state | subscribed_topics: new_subscribed_topics}}
  end

  def handle_cast({:ack, topic}, state) do
    socket = state.socket
    message = %{message_type: :acknowledgement, topic: topic}
    {:ok, encoded_message} = Poison.encode(message)
    :gen_tcp.send(socket, encoded_message)
    {:noreply, state}
  end
end
