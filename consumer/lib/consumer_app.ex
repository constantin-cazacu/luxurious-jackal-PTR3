defmodule ConsumerApp do
  use Application

  def start(_type, _args) do
    children = [
      %{
        id: Consumer,
        start: {Consumer, :start_link, []}
      }
    ]

    opts = [strategy: :one_for_one]

    Supervisor.start_link(children, opts)
  end

end
