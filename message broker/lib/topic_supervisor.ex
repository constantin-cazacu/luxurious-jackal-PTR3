defmodule TopicSupervisor do
  use DynamicSupervisor
  require Logger

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def child_spec(topic) do
    %{
      id: TopicWorker,
      start: {TopicWorker, :start_link, [topic]}
    }
  end

  def create_worker(topic) do
    {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, child_spec(topic))
    TopicRouter.add_topic(topic, pid)
    pid
  end

  def init(_) do
    DynamicSupervisor.init(max_restarts: 200, strategy: :one_for_one)
  end
end
