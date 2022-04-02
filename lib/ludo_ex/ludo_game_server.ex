defmodule LudoEx.LudoGameServer do
  @moduledoc """
  Ludo Game server is a GenServer for handling all the game related process and state
  """
  use GenServer

  def start_link(code, _player) do
    GenServer.start_link(__MODULE__, [], name: String.to_atom(code))
  end

  @impl true
  def init(_arg) do
    {:ok, []}
  end
end
