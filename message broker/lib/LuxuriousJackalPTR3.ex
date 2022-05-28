defmodule LuxuriousJackalPTR3 do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("Starting Application")
    url1 = "http://localhost:4000/tweets/1"
    url2 = "http://localhost:4000/tweets/2"

    children = [
#      %{
#        id: Aggregator,
#        start: {Aggregator, :start_link, []}
#      },
    ]

    opts = [strategy: :one_for_one, max_restarts: 100, name: __MODULE__]

    Supervisor.start_link(children, opts)
  end

end
