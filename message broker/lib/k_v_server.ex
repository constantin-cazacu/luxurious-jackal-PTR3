defmodule KVServer do
  require Logger
  use GenServer

  @doc """
  Starts accepting connections on the given `port`.
  """

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    state = %{socket: socket}
    Logger.info "Accepting connections on port #{port}"
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    Logger.info("[SERVER] Accepting connection from #{inspect(client)}", ansi_color: :blue)
    {:ok, pid} = Task.Supervisor.start_child(KVServer.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    Logger.info("#{inspect(pid)} is serving #{inspect(client)}")
    loop_acceptor(socket)
  end

  defp serve(socket) do
    read_message(socket)
#    socket
#    |> read_message()
#    |> send_message(socket)

    serve(socket)
  end

  def read_message(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    {:ok, message} = Poison.decode(data)
    if Map.has_key?(message, "message_type") do
      Logger.info("incoming message #{inspect(message)} from #{inspect(socket)}", ansi_color: :green)
      message_type = Map.get(message, "message_type")
      Logger.info("[TCP WORKER] Message_type: #{message_type}", ansi_color: :light_magenta)
      case message_type do
        message_type when message_type === "connect" ->
          Logger.info("[TCP WORKER] asking for topic list", ansi_color: :light_blue)
          topic_list = TopicRouter.topic_list_request()
          Logger.info("[TCP WORKER] topic list: #{inspect(topic_list)}", ansi_color: :light_yellow)
          send_topic_list(topic_list, self(), socket)
        message_type when message_type === "subscribe" ->
          topic = Map.get(message, "topic")
          Logger.info("[TCP WORKER] chosen topic: #{inspect(topic)}", ansi_color: :cyan)
          TopicWorker.add_consumer(topic, self(), socket)
        message_type when message_type === "unsubscribe" ->
          topic = Map.get(message, "topic")
          TopicWorker.remove_consumer(topic, self())
        message_type when message_type === "acknowledgement" ->
          topic = Map.get(message, "topic")
          TopicWorker.receive_acknowledgement(:ack, topic, self(), socket)
        _->
          :ok
      end
    else
      TopicRouter.receive_message(message)
    end
  end

  def send_message(message, tcp_pid, socket) do
#    GenServer.cast(tcp_pid, {:send_message, message, socket})
    {:ok, encoded_message} = Poison.encode(message)
    :gen_tcp.send(socket, "#{encoded_message}\n\r")
  end

  def send_topic_list(topic_list, tcp_pid, socket) do
#    Logger.info("I doing a Gen Server cast sending socket: #{inspect(socket)} list: #{inspect(topic_list)}", ansi_color: :green)
#    GenServer.cast(self(), {:end_topic_list, topic_list, socket})
#    Logger.info("here in handle cast", ansi_color: :green)
    {:ok, encoded_message} = Poison.encode(topic_list)
    :gen_tcp.send(socket, "#{encoded_message}\n\r")
  end

  def init(state) do
    {:ok, state}
  end
#
#  def handle_cast({:send_message, message, socket}, state) do
#    {:ok, encoded_message} = Poison.encode(message)
#    :gen_tcp.send(socket, "#{encoded_message}\n\r")
#    {:noreply, state}
#  end
#
#  def handle_cast({:send_topic_list, topic_list, socket}, state) do
#    Logger.info("here in handle cast", ansi_color: :green)
#    {:ok, encoded_message} = Poison.encode(topic_list)
#    :gen_tcp.send(socket, "#{encoded_message}\n\r")
#    {:noreply, state}
#  end
end
