defmodule LudoExWeb.GameLive do
  @moduledoc """
  Ludo game Live view module
  """
  use LudoExWeb, :live_view

  import Phoenix.HTML.Form

  alias LudoEx.GameMoves
  alias LudoEx.GamePlayer
  alias LudoEx.LudoGame
  alias Phoenix.PubSub

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, changeset: GamePlayer.changeset(%{}), roll_value: 1)}
  end

  @impl true
  def handle_params(
        %{"code" => game_code, "player" => player_id},
        _uri,
        %{assigns: %{live_action: :game_play}} = socket
      ) do
    if LudoGame.game_server_exists?(game_code) do
      PubSub.subscribe(LudoEx.PubSub, "game:#{game_code}")

      socket =
        socket
        |> assign(:game_code, game_code)
        |> assign(:player_id, player_id)
        |> assign(:current_player, LudoGame.get_current_player(game_code))
        |> assign(:active_game_players, LudoGame.get_active_game_players(game_code))

      {:noreply, socket}
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
      PubSub.subscribe(LudoEx.PubSub, "game:#{game_code}")

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

  def handle_event(
        "roll_dice",
        _,
        %{
          assigns: %{
            game_code: game_server,
            current_player: %{id: id} = player,
            player_id: player_id
          }
        } = socket
      ) do
    if id === player_id do
      Process.send_after(
        self(),
        {:dice_value, GameMoves.player_dice_move(game_server, player)},
        800
      )
    end

    {:noreply, socket}
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

  def handle_info({:dice_value, dice}, socket) do
    {:noreply, assign(socket, :roll_value, dice)}
  end

  def handle_info({:new_game_play_move, game_code}, socket) do
    socket =
      socket
      |> assign(:current_player, LudoGame.get_current_player(game_code))
      |> assign(:active_game_players, LudoGame.get_active_game_players(game_code))

    {:noreply, socket}
  end

  def can_roll_dice?(_game_code, _player_id) do
    true
  end
end
