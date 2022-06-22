defmodule LuxuriousJackalPTR3 do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("Starting Application")
    port = 8082

    children = [
      {Task.Supervisor, name: KVServer.TaskSupervisor},
            Supervisor.child_spec({Task, fn -> KVServer.accept(port) end}, restart: :permanent),
      %{
        id: TopicSupervisor,
        start: {TopicSupervisor, :start_link, []}
      },
      %{
        id: TopicRouter,
        start: {TopicRouter, :start_link, []}
      }
    ]

    opts = [strategy: :one_for_one, max_restarts: 100, name: __MODULE__]

    Supervisor.start_link(children, opts)
  end

end
