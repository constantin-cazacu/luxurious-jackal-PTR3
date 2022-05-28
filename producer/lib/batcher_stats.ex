defmodule BatcherStats do
  use GenServer
  require Logger

  def start_link() do
    Logger.info("Batch Stats has started", ansi_color: :yellow)
    state = %{
    execution_times: [],
    ingested_messages: 0
    }
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def add_execution_time(time) do
    GenServer.cast(__MODULE__, {:add_execution_time, time})
  end

  def add_ingested_messages(batch_size) do
    GenServer.cast(__MODULE__, {:add_ingested_meesages, batch_size})
  end

  defp reset_stats() do
    pid = self()
    spawn(
    fn ->
      Process.sleep(5000)
      GenServer.cast(pid, :reset)
    end
    )
  end

  defp percentile(list, value) do
    sorted = Enum.sort(list)
    ratio = value / 100.0 * (Kernel.length(list) - 1)
    truncated = Kernel.trunc(ratio)
    lower = Enum.at(sorted, truncated)
    upper = Enum.at(sorted, truncated + 1)
    result = lower + (upper - lower) * (ratio - truncated)
    Float.ceil(result, 2)
  end

  defp average(list) do
    Enum.sum(list) / Kernel.length(list)
  end

  def init(state) do
    reset_stats()
    {:ok, state}
  end

  def handle_cast({:add_execution_time, time}, state) do
    {:noreply, %{state | execution_times: Enum.concat(state.execution_times, [time])}}
  end

  def handle_cast({:add_ingested_meesages, batch_size}, state) do
    {:noreply, %{state | ingested_messages: state.ingested_messages + batch_size}}
  end

  def handle_cast(:reset, state) do
    execution_times = state.execution_times
    ingested_messages = state.ingested_messages
    if Kernel.length(execution_times) > 0 do
      avg_exec_time = average(execution_times)
      percentile_75 = percentile(execution_times, 75)
      percentile_85 = percentile(execution_times, 85)
      percentile_95 = percentile(execution_times, 95)
      Logger.info("[Batcher Stats] Average Exec Time: #{avg_exec_time} \n Percentile Stats: \n 75% = #{percentile_75} \n 85% = #{percentile_85} \n 95% = #{percentile_95}", ansi_color: :green)
    end
    Logger.info("[Batcher Stats] Ingested Messages: #{ingested_messages}", ansi_color: :blue)
    reset_stats()
    {:noreply, %{execution_times: [], ingested_messages: 0}}
  end

end
