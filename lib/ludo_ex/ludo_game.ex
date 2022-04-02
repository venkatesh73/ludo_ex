defmodule LudoEx.LudoGame do
  @moduledoc """
  LudoGame module is used as an APIClient to interact with between Client and the Server
  """
  alias LudoEx.GameServer
  alias LudoEx.GameSupervisor, as: Supervisor

  defdelegate get_game_players(game_server), to: GameServer
  defdelegate game_server_exists?(game_server), to: GameServer
  defdelegate start_game_play(game_server), to: GameServer

  @spec start_join_game(LudoEx.GamePlayer.t()) :: any()
  def start_join_game(%LudoEx.GamePlayer{game_code: code} = player) do
    with false <- game_server_exists?(code),
         :ok <- Supervisor.start_game_server(code) do
      GameServer.add_player_to_the_game(player)
    else
      true ->
        GameServer.add_player_to_the_game(player)

      :game_server_already_started ->
        GameServer.add_player_to_the_game(player)
    end
  end
end
