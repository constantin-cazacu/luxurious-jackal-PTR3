defmodule RetweetAnalysis.AutoScaler do
  use GenServer
  require Logger

  def start_link() do
    Logger.info("Starting Retweet Auto-Scaler", ansi_color: :yellow)
    count_tweets = 0
    GenServer.start_link(__MODULE__, count_tweets, name: __MODULE__)
  end

  def receive_notification() do
    GenServer.cast(__MODULE__, :receive_notification)
  end

  # Server start_module callback
  def init(count_tweets) do
    Process.send_after(self(), :work, 1000)
    {:ok, count_tweets}
  end

  def handle_info(:work, count_tweets) do
    # Start the timer again
    Process.send_after(self(), :work, 1000)

    # Autoscaling workers
    if rem(count_tweets, 4) > 0 do
      worker_number = div(count_tweets, 4) + 1
      active_workers = DynamicSupervisor.count_children(RetweetAnalysis.PoolSupervisor).active
      desired_worker_nr = worker_number - active_workers
      RetweetAnalysis.PoolSupervisor.start_worker(desired_worker_nr)
    else
      worker_number = div(count_tweets, 4)
      active_workers = DynamicSupervisor.count_children(RetweetAnalysis.PoolSupervisor).active
      desired_worker_nr = worker_number - active_workers
      RetweetAnalysis.PoolSupervisor.start_worker(desired_worker_nr)
    end
    {:noreply, 0}
  end

  def handle_cast(:receive_notification, count_tweets) do
    {:noreply, count_tweets + 1}
  end
end
