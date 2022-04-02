defmodule LudoExWeb.AdminLive do
  @moduledoc """
  Ludo Game Admin Dashboards live view module
  """
  use LudoExWeb, :live_view

  alias LudoEx.GameServer

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:games_online, GameServer.get_online_games())

    {:ok, socket}
  end

  def players_count(game_server) do
    game_server
    |> GameServer.get_game_players()
    |> Enum.filter(fn {_, %{is_player?: is_player?}} -> is_player? == true end)
    |> Enum.count()
  end

  def spectator_count(game_server) do
    game_server
    |> GameServer.get_game_players()
    |> Enum.filter(fn {_, %{is_player?: is_player?}} -> is_player? == false end)
    |> Enum.count()
  end
end
