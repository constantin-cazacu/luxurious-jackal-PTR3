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
    {:ok, pid} = Task.Supervisor.start_child(KVServer.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
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
#    Logger.info(inspect(data), ansi_color: :green)
    {:ok, message} = Poison.decode(data)
    if Map.has_key?(message, :message_type) do
      message_type = Map.get(message, :message_type)
      case message_type do
        message_type when message_type === :connect ->
          topic_list = TopicRouter.topic_list_request()
          send_message(topic_list, socket)
        message_type when message_type === :subscribe ->
          topic = Map.get(message, :topic)
          TopicWorker.add_consumer(topic, self())
        message_type when message_type === :unsubscribe ->
          topic = Map.get(message, :topic)
          TopicWorker.remove_consumer(topic, self())
        message_type when message_type === :acknowledgement ->
          topic = Map.get(message, :topic)
          TopicWorker.receive_acknowledgement(:ack, topic, self())
      end
    else
      TopicRouter.receive_message(message)
    end
  end

  def send_message(message, tcp_pid) do
    GenServer.cast(tcp_pid, {:send_message, message})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:send_message, message}, state) do
    socket = state.socket
    {:ok, encoded_message} = Poison.encode(message)
    :gen_tcp.send(socket, encoded_message)
    {:noreply, state}
  end
end
