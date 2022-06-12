defmodule KVServer do
  require Logger

  @doc """
  Starts accepting connections on the given `port`.
  """
  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port,
      [:binary, packet: :line, active: false, reuseaddr: true])
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
    socket
    |> read_message()
    |> send_message(socket)

    serve(socket)
  end

  defp read_message(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    {:ok, message} = Poison.decode(data)
    message
  end

  defp send_message(message, socket) do
#    :gen_tcp.send(socket, message)
    TopicRouter.receive_message(message)
  end
end
