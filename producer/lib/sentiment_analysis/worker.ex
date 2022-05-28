defmodule SentimentAnalysis.Worker do
  use GenServer
  require Logger

  def start_link(index) do
#    Logger.info("Starting Sentiment Worker No.#{index}")
    GenServer.start_link(__MODULE__, %{}, name: String.to_atom("SentimentWorker#{index}"))
  end

  def receive_tweet(pid, id, tweet) do
    GenServer.cast(pid, {id, tweet})
  end

  defp parse_words(tweet_msg) do
    punctuation = [",", ".", ":", "?", "!"]
    tweet_msg
    |> String.replace(punctuation, "")
    |> String.split(" ", trim: true)
  end

  defp calculate_sentiment_score(tweet_words) do
    tweet_words
    |> Enum.reduce(0, fn tweet_word, acc -> EmotionalScore.get_value(tweet_word) + acc end)
    |> Kernel./(length(tweet_words))
  end

  defp parse_tweet(id, tweet_data) do
    tweet_msg = tweet_data["message"]["tweet"]["text"]
    sentiment_score = tweet_msg
                      |> parse_words()
                      |> calculate_sentiment_score()
    Aggregator.add_sentiment_score(id, sentiment_score)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({id, tweet}, state) do
    if tweet == "{\"message\": panic}" do
      Process.exit(self(), :kill)
    end
    {:ok, tweet_data} = Poison.decode(tweet)
    parse_tweet(id, tweet_data)

    #    Process.sleep(Enum.random(50..500))
    {:noreply, state}
  end
end
