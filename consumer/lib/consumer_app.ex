defmodule ConsumerApp do
  use Application

  def start(_type, _args) do
    children = [
    ]

    opts = [strategy: :one_for_one]
    socket = Consumer.open()

    Consumer.receive_message(socket, 0)
    Consumer.unsubscribe(socket)
    Supervisor.start_link(children, opts)
  end

end
