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

  def get_current_player(game_server) do
    GameServer.get_active_game_player(game_server)
  end

  def get_active_game_players(game_server) do
    players = get_game_players(game_server)

    Enum.reduce(players, [], fn {_, %{is_player?: is_player} = player}, acc ->
      if is_player === true do
        [player | acc]
      else
        acc
      end
    end)
  end
end
