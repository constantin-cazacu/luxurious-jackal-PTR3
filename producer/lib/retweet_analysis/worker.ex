defmodule RetweetAnalysis.Worker do
  use GenServer
  require Logger

  def start_link(index) do
#    IO.inspect("Starting Retweet Worker No.#{index}")
    GenServer.start_link(__MODULE__, %{}, name: String.to_atom("RetweetWorker#{index}"))
  end

  def receive_tweet(pid, tweet) do
    GenServer.cast(pid, {:forward_tweet, tweet})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:forward_tweet, tweet}, state) do
    if tweet == "{\"message\": panic}" do
      Process.exit(self(), :kill)
    end
    {:ok, tweet_data} = Poison.decode(tweet)
    tweet_info = tweet_data["message"]["tweet"]
    retweet_status = Map.has_key?(tweet_info, "retweeted_status")
    if retweet_status do
      original_tweet = tweet_data["message"]["tweet"]["retweeted_status"]
      new_tweet_data = %{"message" => %{"tweet" => original_tweet}}
      {:ok, new_tweet} = Poison.encode(new_tweet_data)
      Router.receive_tweet(new_tweet)
    end

    #    Process.sleep(Enum.random(50..500))
    {:noreply, state}
  end
end
