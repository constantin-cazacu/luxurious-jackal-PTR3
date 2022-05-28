defmodule Batcher do
  @moduledoc false
  use GenServer
  require Logger

  @batch_size 99
  @timer_length 1000

  def start_link() do
    Logger.info("Starting Batcher", anis_color: :yellow)
    {:ok, mongo_pid} = Mongo.start_link(url: "mongodb://localhost:27017/TweetDataStream")
    timer_ref = schedule_batcher()
    database_state = 1
    GenServer.start_link(__MODULE__, %{batch: [], records_per_interval: 0, mongo_pid: mongo_pid, timer_ref: timer_ref, database_state: database_state}, name: __MODULE__)
  end

  def add_record(record) do
    GenServer.cast(__MODULE__, {:add, record})
  end

  def schedule_batcher() do
    timer_ref = Process.send_after(self(), :free, @timer_length)
  end

  def send_batch(records, mongo_pid) do
    batch_size = Kernel.length(records)
    init_time = System.monotonic_time()
    Mongo.insert_many(mongo_pid, "tweets", get_tweets(records))
    Mongo.insert_many(mongo_pid, "users", get_users(records))
    exec_time = System.monotonic_time() - init_time
    BatcherStats.add_execution_time(exec_time)
    BatcherStats.add_ingested_messages(batch_size)
  end

  def get_tweets(records) do
    Enum.map(records, fn object -> object.tweet_data end)
  end

  def get_users(records) do
    Enum.map(records, fn object -> object.user end)
  end

  def send_notification() do
    GenServer.cast(__MODULE__, :change_db_state)
  end

  def start_timer() do
    Process.send_after(self(), :timer, 2000)
  end

  def init(state) do
    start_timer()
    {:ok, state}
  end

  def handle_cast({:add, record}, state) do
    record_buffer = [record | state.batch]
    new_records_per_interval = state.records_per_interval + 1
    case state.records_per_interval >= @batch_size do
      true ->
        send_batch(record_buffer, state.mongo_pid)
        Process.cancel_timer(state.timer_ref)
        timer_ref = schedule_batcher()
        {:noreply, %{batch: [], records_per_interval: 0, mongo_pid: state.mongo_pid, timer_ref: timer_ref, database_state: state.database_state}}
      false ->
        {:noreply, %{batch: record_buffer, records_per_interval: new_records_per_interval, mongo_pid: state.mongo_pid, timer_ref: state.timer_ref, database_state: state.database_state}}
    end
  end

  def handle_info(:free, state) do
    if Kernel.length(state.batch) == 0 do
      timer_ref = schedule_batcher()
      {:noreply, %{batch: state.batch, records_per_interval: state.records_per_interval, mongo_pid: state.mongo_pid, timer_ref: timer_ref, database_state: state.database_state}}
    else
      send_batch(state.batch, state.mongo_pid)
      timer_ref = schedule_batcher()
      {:noreply, %{batch: [], records_per_interval: 0, mongo_pid: state.mongo_pid, timer_ref: timer_ref, database_state: state.database_state}}
    end
  end

  def handle_cast(:change_db_state, state) do
    state_list = [0, 1]
    new_state = Enum.random(state_list)
    if state.database_state != new_state do
      Aggregator.receive_notification(new_state)
      Logger.info("Batcher: New state is #{inspect(new_state)}")
      {:noreply, %{state | database_state: new_state}}
    else
      Logger.info("Batcher: Database state is still #{inspect(state.database_state)}")
      {:noreply, state}
    end
  end

  def handle_info(:timer, state) do
    start_timer()
    send_notification()
    {:noreply, state}
  end

end
