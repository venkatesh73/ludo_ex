defmodule LudoEx.LudoGameSupervisor do
  @moduledoc """
  Ludo Game Supervisor is used to manage each Game Server that is when the game is being started.
  """
  use DynamicSupervisor

  alias LudoEx.LudoGameServer, as: GameServer

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_game_join(game_code, player) do
    game_spec = %{id: GameServer, start: {GameServer, :start_link, [game_code, player]}}

    case DynamicSupervisor.start_child(__MODULE__, game_spec)
         |> IO.inspect(label: "------ Start Child Spec ------") do
      {:ok, _pid} ->
        IO.inspect("Successfully Initiated the GameServer")
        :ok

      _ ->
        IO.inspect("Failed to start Game Server")
        :ignored
    end
  end
end
