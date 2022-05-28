defmodule RetweetAnalysis.PoolSupervisor do
  use DynamicSupervisor
  require Logger

  def start_link() do
    Logger.info("Starting Engagement Pool Supervisor", ansi_color: :yellow)
    supervisor = DynamicSupervisor.start_link(__MODULE__, %{}, name: __MODULE__)
    start_worker(10)
    supervisor
  end

  def child_spec(index) do
    %{
      id: RetweetWorker,
      start: {RetweetAnalysis.Worker, :start_link, [System.unique_integer([:positive, :monotonic])]}
    }
  end

  def start_worker(auto_scaler_nr) when auto_scaler_nr == 0 do
    :do_nothing
  end

  def start_worker(auto_scaler_nr) do
    active_workers = DynamicSupervisor.count_children(__MODULE__).active
    case auto_scaler_nr do
      auto_scaler_nr when (auto_scaler_nr > 0) ->
        {:ok, worker_pid} = DynamicSupervisor.start_child(__MODULE__, child_spec(active_workers))
        RetweetAnalysis.LoadBalancer.send_worker_pid(worker_pid)
        start_worker(auto_scaler_nr-1)

      auto_scaler_nr when (auto_scaler_nr < 0) ->
        RetweetAnalysis.LoadBalancer.terminate_workers(auto_scaler_nr)
      _ ->
        :do_nothing
    end
  end

  def init(_) do
    DynamicSupervisor.init(max_restarts: 200, strategy: :one_for_one)
  end
end
