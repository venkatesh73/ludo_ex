defmodule LudoExWeb.GameLive do
  @moduledoc """
  Ludo game Live view module
  """
  use LudoExWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"code" => game_code}, _uri, %{assigns: %{live_action: action}} = socket)
      when action in [:lobby, :game_play] do
    IO.inspect(game_code, label: "------ game code in here ------")
    {:noreply, socket}
  end

  def handle_params(_params, _uri, %{assigns: %{live_action: :multiplayer}} = socket) do
    {:noreply, socket}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("start_game", _params, socket) do
    IO.inspect("------ I am creating an game code in here and start the game server -----")
    {:noreply, socket}
  end
end
