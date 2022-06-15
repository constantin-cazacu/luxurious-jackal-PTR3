defmodule Consumer do

  def subscribe() do
    {:ok, socket} = :gen_tcp.connect('127.0.0.1', 8082)
#    TODO find ways to write commands, or user input
    {:ok, encoded_message} = Poison.encode(:subscribe_to_topic_command)
    :gen_tcp.send(socket, encoded_message)
    socket
  end

  def unsubscribe(socket) do
    {:ok, encoded_message} = Poison.encode(:unsubscribe_from_topic_command)
    :gen_tcp.send(socket, encoded_message)
  end

  def receive_message(socket, index) do
    
  end
end
