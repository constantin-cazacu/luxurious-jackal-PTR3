defmodule Router do
  @moduledoc false
  use GenServer
  require Logger

  def start_link() do
    Logger.info("Starting Router", ansi_color: :yellow)
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def receive_tweet(tweet) do
    id = System.unique_integer([:positive, :monotonic])
    GenServer.cast(__MODULE__, {id, tweet})
  end

  def init(_opts) do
    {:ok, %{}}
  end

  def handle_cast({id, tweet}, state) do
#    Logger.info("tweet: #{inspect(tweet)}")
    EngagementAnalysis.LoadBalancer.get_tweet(id, tweet)
    EngagementAnalysis.AutoScaler.receive_notification()
    RetweetAnalysis.LoadBalancer.get_tweet(id, tweet)
    RetweetAnalysis.AutoScaler.receive_notification()
    SentimentAnalysis.LoadBalancer.get_tweet(id, tweet)
    SentimentAnalysis.AutoScaler.receive_notification()
    Aggregator.add_tweet_info(id, tweet)
    {:noreply, state}
  end

end