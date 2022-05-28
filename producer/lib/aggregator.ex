defmodule Aggregator do
  use GenServer
  require Logger

  def start_link() do
    Logger.info("Aggregator has started", ansi_color: :yellow)
    database_state = 1
    GenServer.start_link(__MODULE__, %{records: %{}, stored_objects: [], database_state: database_state}, name: __MODULE__)
  end

  def add_engagement_score(id, engagement_score) do
    GenServer.cast(__MODULE__, {:engagement, {id, engagement_score}})
  end

  def add_sentiment_score(id, sentiment_score) do
    GenServer.cast(__MODULE__, {:sentiment, {id, sentiment_score}})
  end

  def add_tweet_info(id, tweet) do
    if tweet == "{\"message\": panic}" do
      :ok
    else
      {:ok, tweet_data} = Poison.decode(tweet)
      GenServer.cast(__MODULE__, {:tweet, {id, tweet_data}})
    end
  end

  def get_records(id, records) do
    has_key = Map.has_key?(records, id)
    case has_key do
      false ->
        Map.put(records, id, %{})
      _ ->
        records
    end
  end

  def update_record(records, id, record_type, info) do
    record = Map.get(records, id)
    returned_record = Map.put(record, record_type, info)
    returned_record
  end

  def update_record_by_id(records, id, new_record) do
    Map.update!(records, id, fn _obsolete_record -> new_record end)
  end

  def get_keys_number(record) do
    record
    |> Map.keys()
    |> Kernel.length()
  end

  def create_object(record) do
    tweet = record["tweet"]["message"]["tweet"]
    user = tweet["user"]
    tweet = Map.update!(tweet, "user", fn user -> user["id"] end)

    %{
      tweet_data: %{
        engagement_score: record["engagement"],
        sentiment_score: record["sentiment"],
        tweet: tweet},
      user: user}
  end

  def create_record(record_type, info, id, state) do
    records = get_records(id, state.records)
    record = update_record(records, id, record_type, info)
    records = update_record_by_id(records, id, record)
    case get_keys_number(record) do
      3 ->
        object = create_object(record)
        if state.database_state == 0 do
          pause_stream(object)
          Map.delete(state.records, id)
        else
          resume_stream()
          Batcher.add_record(object)
          Map.delete(state.records, id)
        end
      _ ->
        records
    end
  end

  def pause_stream(object) do
    GenServer.cast(__MODULE__, {:pause, object})
  end

  def receive_notification(database_state) do
    Logger.info("Aggregator: Notification received", ansi_color: :green)
    GenServer.cast(__MODULE__, {:receive_notification, database_state})
  end

  def resume_stream() do
    GenServer.cast(__MODULE__, :resume)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:engagement, {id, engagement_score}}, state) do
    records = create_record("engagement", engagement_score, id, state)
    {:noreply, %{state | records: records}}
  end

  def handle_cast({:sentiment, {id, sentiment_score}}, state) do
    records = create_record("sentiment", sentiment_score, id, state)
    {:noreply, %{state | records: records}}
  end

  def handle_cast({:tweet, {id, tweet_data}}, state) do
    records = create_record("tweet", tweet_data, id, state)
    {:noreply, %{state | records: records}}
  end

  def handle_cast({:receive_notification, database_state}, state) do
    {:noreply, %{state | database_state: database_state}}
  end

  def handle_cast({:pause, object}, state) do
    object_list = [object | state.stored_objects]
#    Logger.info("Aggregator: list in pause #{inspect(length(object_list))}")
    {:noreply, %{state | stored_objects: object_list}}
  end

  def handle_cast(:resume, state) do
    if length(state.stored_objects) > 0 do
      Enum.each(state.stored_objects, fn object -> Batcher.add_record(object) end)
#      Logger.info("Aggregator: resumed list #{inspect(length(state.stored_objects))}", ansi_color: :light_blue)
    end
    {:noreply, %{state | stored_objects: []}}
  end

end