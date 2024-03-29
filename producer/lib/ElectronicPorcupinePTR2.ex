defmodule ElectronicPorcupinePTR2 do
  use Application
  require Logger

  @moduledoc """
  Documentation for `TweetProcessor`.
  """

  @impl true
  def start(_type, _args) do
    Logger.info("Starting Application")
    url1 = "http://localhost:4000/tweets/1"
    url2 = "http://localhost:4000/tweets/2"
    port = String.to_integer(System.get_env("PORT") || "4040")

    children = [
#      {Task.Supervisor, name: KVServer.TaskSupervisor},
#      Supervisor.child_spec({Task, fn -> KVServer.accept(port) end}, restart: :permanent)
#      %{
#        id: Aggregator,
#        start: {Aggregator, :start_link, []}
#      },
#      %{
#        id: BatcherStats,
#        start: {BatcherStats, :start_link, []}
#      },
#      %{
#        id: Batcher,
#        start: {Batcher, :start_link, []}
#      },
#      %{
#        id: RetweetAnalysis.TopSupervisor,
#        start: {RetweetAnalysis.TopSupervisor, :start_link, []}
#      },
#      %{
#        id: SentimentAnalysis.TopSupervisor,
#        start: {SentimentAnalysis.TopSupervisor, :start_link, []}
#      },
#      %{
#        id: EngagementAnalysis.TopSupervisor,
#        start: {EngagementAnalysis.TopSupervisor, :start_link, []}
#      },
#      %{
#        id: Router,
#        start: {Router, :start_link, []}
#      },
#      %{
#        id: StreamReader1,
#        start: {StreamReader, :start_link, [url1]}
#      },
#      %{
#        id: StreamReader2,
#        start: {StreamReader, :start_link, [url2]}
#      },
      %{
        id: BrokerConnector,
        start: {BrokerConnector, :start_link, [8082, "users"] }
      }
    ]

    opts = [strategy: :one_for_one, max_restarts: 100, name: __MODULE__]

    Supervisor.start_link(children, opts)
  end
end
