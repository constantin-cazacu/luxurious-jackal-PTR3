defmodule Timer do
  use GenServer
  require Logger

  def start_link() do
    state = %{timer_ref: :empty, message: "", tcp_pid: "", socket: ""}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def start_timer(message, tcp_pid, socket) do
    GenServer.cast(self(), {:timer, message, tcp_pid, socket})
  end

  def restart_timer() do
    GenServer.cast(self(), :restart)
  end

  def restart_timer(:restart, state) do
    Logger.info("[TIMER] restarting timer")
    timer_ref = state.timer_ref
    Process.cancel_timer(timer_ref)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_info(:timeout, state) do
    message = state.message
    tcp_pid = state.tcp_pid
    socket = state.socket
    KVServer.send_message(message, tcp_pid, socket)
    {:noreply, state}
  end

  def handle_cast({:timer, message, tcp_pid, socket}, state) do
    timer_ref = Process.send_after(self(), :timeout, 1000)
    {:ok, %{state | timer_ref: timer_ref, message: message, tcp_pid: tcp_pid, socket: socket}}
  end

end
