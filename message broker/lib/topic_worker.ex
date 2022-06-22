defmodule TopicWorker do
  use GenServer
  require Logger

#  TODO add DETS [not now, in the future]

  def start_link(topic) do
    subscriber_list = :ets.new(:subs_list, [:set, :public])
    state = %{message_queue: [], subs_list: subscriber_list}
    GenServer.start_link(__MODULE__, state, name: String.to_atom("#{topic}Worker"))
  end

  def receive_message(message, topic_worker_pid) do
    GenServer.cast(topic_worker_pid, {:add_to_queue, message})
  end

  def add_consumer(topic, tcp_pid, socket) do
    GenServer.cast(String.to_atom("#{topic}Worker"), {:add_consumer, tcp_pid, topic, socket})
  end

  def remove_consumer(topic, tcp_pid) do
    GenServer.cast(String.to_atom("#{topic}Worker"), {:remove_consumer, tcp_pid})
  end

  def receive_acknowledgement(:ack, topic, tcp_pid, socket) do
    Logger.info("Topic Worker receive acknowledgement")
    GenServer.cast(String.to_atom("#{topic}Worker"), {:acknowledgement, tcp_pid, topic, socket})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_cast({:add_to_queue, message}, state) do
    message_queue = state.message_queue
    updated_message_queue = [message | message_queue]
#    Logger.info("Message queue length #{Kernel.length(message_queue)}", ansi_color: :yellow)
    {:noreply, %{state | message_queue: updated_message_queue}}
  end

  def handle_cast({:add_consumer, tcp_pid, topic, socket}, state) do
    subscriber_list = state.subs_list
    Logger.info("[TOPIC WORKER] add consumer handle cast subscribers list #{inspect(subscriber_list)}")
    message_queue = state.message_queue
    index = 0
    :ets.insert(subscriber_list, {tcp_pid, index})
    selected_message = Enum.at(message_queue, index)

    message = %{topic: topic, message: selected_message}
    Logger.info("[TOPIC WORKER] message #{inspect(message)}")
    KVServer.send_message(message, tcp_pid, socket)
    {:noreply, state}
  end

  def handle_cast({:remove_consumer, tcp_pid}, state) do
    subscriber_list = state.subs_list
    :ets.delete(subscriber_list, tcp_pid)
    {:noreply, state}
  end

  def handle_cast({:acknowledgement, tcp_pid, topic, socket}, state) do
    Logger.info("I'm in ack handle")
    subscriber_list = state.subs_list
    message_queue = state.message_queue
    Logger.info("Message queue is #{inspect(message_queue)}")
    new_index = :ets.update_counter(subscriber_list, tcp_pid, 1)
    selected_message = Enum.at(message_queue, new_index)
    Logger.info("Selected message #{inspect(selected_message)}")
    message = %{topic: topic, message: selected_message}
    Logger.info("this is message #{inspect(message)}")
    KVServer.send_message(message, tcp_pid, socket)
    Logger.info("the message was sent")
    {:noreply, state}
  end
end
