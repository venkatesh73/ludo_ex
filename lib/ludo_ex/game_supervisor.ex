defmodule LudoEx.GameSupervisor do
  @moduledoc """
  Ludo Game Supervisor is used to manage each Game Server that is when the game is being started.
  """
  use DynamicSupervisor
  require Logger

  alias LudoEx.GameServer

  def start_link(_args) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_game_server(String.t()) :: :ok | :game_server_already_started
  def start_game_server(game_code) do
    game_spec = %{id: GameServer, start: {GameServer, :start_link, [game_code]}}

    case DynamicSupervisor.start_child(__MODULE__, game_spec) do
      {:ok, _game_process} ->
        Logger.info("Game server : #{game_code} has been started successfully.")
        :ok

      {:error, _} ->
        Logger.error("Supervisor failed to start Game Server for #{game_code}")
        :game_server_already_started
    end
  end

  def terminate(game_server) do
    DynamicSupervisor.terminate_child(__MODULE__, game_server)
  end
end
