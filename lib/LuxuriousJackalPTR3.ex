defmodule LuxuriousJackalPTR3 do
  use Application
  require Logger
  @moduledoc """
  Documentation for `LuxuriousJackalPtr3`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> LuxuriousJackalPtr3.hello()
      :world

  """
  def start(_type, _args) do
    :world
    Logger.info("Hi mortal")
  end

end
