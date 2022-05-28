defmodule EngagementAnalysis.Worker do
  use GenServer
  require Logger

  def start_link(index) do
#    Logger.info("Starting Engagement Worker No.#{index}", ansi_color: :yellow)
    GenServer.start_link(__MODULE__, %{}, name: String.to_atom("EngagementWorker#{index}"))
  end

  def receive_tweet(pid, id, tweet) do
    GenServer.cast(pid, {id, tweet})
  end

  defp calculate_engagement_score(favourites_count, 0, retweet_count) do
    favourites_count + retweet_count
  end

  defp calculate_engagement_score(favourites_count, follower_count, retweet_count) do
    (favourites_count + retweet_count) / follower_count
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({id, tweet}, state) do
    if tweet == "{\"message\": panic}" do
      Process.exit(self(), :kill)
    end
    {:ok, tweet_data} = Poison.decode(tweet)
    favourites_count = tweet_data["message"]["tweet"]["favorite_count"]
    follower_count = tweet_data["message"]["tweet"]["user"]["followers_count"]
    retweet_count = tweet_data["message"]["tweet"]["retweet_count"]
    engagement_score = calculate_engagement_score(favourites_count, follower_count, retweet_count)
    Aggregator.add_engagement_score(id, engagement_score)
    #    Process.sleep(Enum.random(50..500))
    {:noreply, state}
  end
end
