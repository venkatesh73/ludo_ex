defmodule LudoExWeb.GameLive do
  @moduledoc """
  Ludo game Live view module
  """
  use LudoExWeb, :live_view

  import Phoenix.HTML.Form

  alias LudoEx.GamePlayer
  alias LudoEx.LudoGame
  alias Phoenix.PubSub

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, changeset: GamePlayer.changeset(%{}))}
  end

  @impl true
  def handle_params(
        %{"code" => game_code, "player" => player_id},
        _uri,
        %{assigns: %{live_action: :game_play}} = socket
      ) do
    if LudoGame.game_server_exists?(game_code) do
      {:noreply, assign(socket, game_code: game_code, player_id: player_id)}
    else
      socket =
        socket
        |> put_flash(
          :error,
          "The Game your'e trying to Join is either already terminated."
        )
        |> push_patch(to: Routes.game_path(socket, :index))

      {:noreply, socket}
    end
  end

  def handle_params(
        %{"code" => game_code, "player" => player_id},
        _uri,
        %{assigns: %{live_action: :lobby}} = socket
      ) do
    if LudoGame.game_server_exists?(game_code) do
      socket =
        socket
        |> assign(:game_code, game_code)
        |> assign(:player_id, player_id)
        |> assign(:players, LudoGame.get_game_players(game_code))

      {:noreply, socket}
    else
      socket =
        socket
        |> put_flash(
          :error,
          "The Game your'e trying to Join is either Not Started yet/Already terminated."
        )
        |> push_patch(to: Routes.game_path(socket, :index))

      {:noreply, socket}
    end
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("join_game", %{"game_player" => game_player}, socket) do
    with {:ok, %GamePlayer{} = player} <-
           GamePlayer.new(game_player),
         {:ok, {player_id, game_code}} <- LudoGame.start_join_game(player) do
      PubSub.subscribe(LudoEx.PubSub, "game:#{game_code}")
      {:noreply, push_patch(socket, to: Routes.game_path(socket, :lobby, game_code, player_id))}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

      {:game_started, {player_id, game_code}} ->
        {:noreply,
         push_patch(socket, to: Routes.game_path(socket, :game_play, game_code, player_id))}

      :player_limit_exceed ->
        socket =
          socket
          |> put_flash(:info, "Game player limit exceeded.")
          |> push_patch(to: Routes.game_path(socket, :index))

        {:noreply, socket}

      {:player_added_as_spectator, {player_id, game_code}} ->
        socket =
          socket
          |> put_flash(:info, "You have been added as a Spectator, you can't play the game.")
          |> push_patch(to: Routes.game_path(socket, :game_play, game_code, player_id))

        {:noreply, socket}

      :game_terminated ->
        socket =
          socket
          |> put_flash(:info, "The Game your'e trying to Join is either already terminated.")
          |> push_patch(to: Routes.game_path(socket, :index))

        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:new_player_joined, game_code}, socket) do
    {:noreply, assign(socket, :players, LudoGame.get_game_players(game_code))}
  end

  def handle_info(
        {:game_started},
        %{assigns: %{game_code: game_code, player_id: player_id}} = socket
      ) do
    socket =
      socket
      |> put_flash(:info, "Game Play has been started.")
      |> push_patch(to: Routes.game_path(socket, :game_play, game_code, player_id))

    {:noreply, socket}
  end
end
