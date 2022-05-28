defmodule EngagementAnalysis.LoadBalancer do
  use GenServer
  require Logger

  def start_link() do
    worker_list = []
    index = 0
    Logger.info("Starting Engagement Load Balancer", ansi_color: :yellow)
    GenServer.start_link(__MODULE__, {worker_list, index}, name: __MODULE__)
  end

  def get_tweet(id, tweet) do
    GenServer.cast(__MODULE__, {:receive_tweet, {id, tweet}})
  end

  def send_worker_pid(worker_pid) do
    GenServer.cast(__MODULE__, {:add_worker, worker_pid})
  end

  def terminate_workers(workers_to_kill) do
    GenServer.cast(__MODULE__, {:kill_workers, workers_to_kill})
  end

  def delete_from_list(list_of_workers_to_kill) do
    if length(list_of_workers_to_kill) > 0 do
      pid_to_kill = Enum.at(list_of_workers_to_kill, -1)
      safe_termination(pid_to_kill)
      new_list_to_kill = Enum.drop(list_of_workers_to_kill,-1)
      delete_from_list(new_list_to_kill)
    else
      :noreply
    end
  end

  def safe_termination(pid_to_kill) do
    if Process.alive?(pid_to_kill) == false do
#      IO.inspect("[Engagement Load Balancer]> The process is not alive")
    else
      {:message_queue_len, list_length} = Process.info(pid_to_kill, :message_queue_len)
      if list_length > 0 do
        Process.send_after(pid_to_kill, {:terminate_work, pid_to_kill}, 5000)
      else
        DynamicSupervisor.terminate_child(EngagementAnalysis.PoolSupervisor, pid_to_kill)
      end
    end
  end

  def init(index) do
    {:ok, index}
  end

  def handle_cast({:receive_tweet, {id, tweet}}, state) do
    {worker_list, index} = state
    if length(worker_list) > 0 do
      worker_pid = Enum.at(worker_list, rem(index, length(worker_list)))
      EngagementAnalysis.Worker.receive_tweet(worker_pid, id, tweet)
    end
    {:noreply, {worker_list, index + 1}}
  end

  def handle_cast({:add_worker, worker_pid}, state) do
    {worker_list, index} = state
    active_worker_list = Enum.concat(worker_list, [worker_pid])
    {:noreply, {active_worker_list, index}}
  end

  def handle_cast({:kill_workers, workers_to_kill}, state) do
    {worker_list, index} = state
    list_of_workers_to_kill = Enum.take(worker_list, workers_to_kill)
#    IO.inspect("Engagement Load Balancer: Workers to kill #{inspect(list_of_workers_to_kill)}")
    new_worker_list = Enum.drop(worker_list, length(list_of_workers_to_kill) * (-1))
    delete_from_list(list_of_workers_to_kill)
    {:noreply, {new_worker_list, index}}
  end

  def handle_info({:terminate_work, pid_to_kill}, state) do
    #    Logger.info("Engagement Load Balancer: pid will be killed #{pid_to_kill}", ansi_color: :white)
    safe_termination(pid_to_kill)
    {:noreply, state}
  end
end
