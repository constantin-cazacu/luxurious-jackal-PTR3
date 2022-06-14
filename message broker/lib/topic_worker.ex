defmodule TopicWorker do
  use GenServer
  require Logger

#  TODO logic for consumer
#     TODO tcp connection for consumers
#     TODO subscribe / unsubscribe to topics functionality
#     TODO message acknowledgement

#  TODO add DETS [not now, in the future]

  def start_link(topic) do
    state = %{message_queue: []}
    GenServer.start_link(__MODULE__, name: String.to_atom("#{topic}Worker"))
  end

  def receive_message(message, topic_worker_pid) do
    {topic, data} = message
    GenServer.cast(topic_worker_pid, {:add_to_queue, message})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:add_to_queue, message}, state) do
    message_queue = state.message_queue
    updated_message_queue = [message | message_queue]
    {:noreply, %{state | message_queue: updated_message_queue}}
  end
end
