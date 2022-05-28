defmodule RetweetAnalysis.TopSupervisor do
  use Supervisor
  require Logger

  def start_link() do
    IO.inspect("Starting Retweet Top Supervisor", ansi_color: :yellow)
    Supervisor.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    children = [
      %{
        id: RetweetLoadBalancer,
        start: {RetweetAnalysis.LoadBalancer, :start_link, []}
      },
      %{
        id: RetweetAutoScaler,
        start: {RetweetAnalysis.AutoScaler, :start_link, []}
      },
      %{
        id: RetweetPoolSupervisor,
        start: {RetweetAnalysis.PoolSupervisor, :start_link, []}
      },
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 100)
  end

end
