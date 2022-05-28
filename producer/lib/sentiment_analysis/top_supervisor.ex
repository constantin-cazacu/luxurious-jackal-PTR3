defmodule SentimentAnalysis.TopSupervisor do
  use Supervisor
  require Logger

  def start_link() do
    IO.inspect("Starting Sentiment Top Supervisor", ansi_color: :yellow)
    Supervisor.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    children = [
      %{
        id: SentimentLoadBalancer,
        start: {SentimentAnalysis.LoadBalancer, :start_link, []}
      },
      %{
        id: SentimentAutoScaler,
        start: {SentimentAnalysis.AutoScaler, :start_link, []}
      },
      %{
        id: SentimentPoolSupervisor,
        start: {SentimentAnalysis.PoolSupervisor, :start_link, []}
      },
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 100)
  end
end
