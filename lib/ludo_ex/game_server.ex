defmodule LudoEx.GameServer do
  @moduledoc """
  Ludo Game server is a GenServer for handling all the game related process and state
  """
  use GenServer
  require Logger

  alias LudoEx.GamePlayer
  alias LudoEx.GameState
  alias Phoenix.PubSub

  def start_link(code) do
    GenServer.start_link(__MODULE__, code, name: via_tuple(code))
  end

  @impl true
  def init(code) do
    {:ok, GameState.new(%{"code" => code})}
  end

  @impl true
  def handle_info({:terminate_child, game_server}, state) do
    Logger.info("Game Server Will be Terminated if no minimum player joined.")
    LudoEx.GameSupervisor.terminate(game_server)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:game_start}, state) do
    new_state = Map.update(state, :state, :started, fn _ -> :started end)
    {:noreply, new_state}
  end

  def handle_cast({:make_player_move, player_id, player}, state) do
    players = Map.get(state, :players)
    updated_players = Map.update(players, player_id, players[player_id], fn _ -> player end)
    {:noreply, Map.update(state, :players, players, fn _ -> updated_players end)}
  end

  def handle_cast({:next_player_move, player_id}, %{players: players} = state) do
    max_players = Enum.count(players) - 1

    {_, next_player} =
      case Enum.find_index(players, fn {id, _} -> id == player_id end) do
        idx when idx === max_players ->
          Enum.at(players, 0)

        idx ->
          Enum.at(players, idx + 1)
      end

    updated_player =
      Enum.reduce(players, [], fn {id, player}, acc ->
        if id == next_player.id do
          acc ++ [{id, %{player | can_roll_dice?: true}}]
        else
          acc ++ [{id, %{player | can_roll_dice?: false}}]
        end
      end)

    {:noreply, Map.update(state, :players, players, fn _ -> updated_player end)}
  end

  #### Sync API Calls ####
  @doc """
  """
  @impl true
  def handle_call({:get_games_player_count}, _from, state) do
    count =
      state
      |> Map.get(:players, [])
      |> Enum.count()

    {:reply, count, state}
  end

  def handle_call({:get_all_game_players}, _from, state) do
    {:reply, Map.get(state, :players, []), state}
  end

  def handle_call({:add_player_to_game, player}, _from, state) do
    case validate_and_add_player_to_game(state, player) do
      {:ok, new_state} ->
        {:reply, :player_added_successfully, new_state}

      {:player_exceeded, new_state} ->
        {:reply, :player_limit_exceed, new_state}

      {:spectator, new_state} ->
        {:reply, :player_added_as_spectator, new_state}

      :game_terminated ->
        {:reply, :game_terminated, state}
    end
  end

  def handle_call({:get_active_player_id}, _from, state) do
    [{_, player} | _] =
      Enum.filter(
        state.players,
        fn {id, %{can_roll_dice?: can_roll}} ->
          if can_roll === true, do: id
        end
      )

    {:reply, player, state}
  end

  ### Client Calls ###
  def get_online_games do
    Registry.select(LudoEx.GameRegistry, [{{:"$1", :"$2", :"$3"}, [], [:"$1"]}])
  end

  def add_player_to_the_game(%GamePlayer{id: id, game_code: code} = player) do
    case GenServer.call(via_tuple(code), {:add_player_to_game, player}) do
      :player_added_successfully ->
        PubSub.broadcast!(LudoEx.PubSub, "game:#{code}", {:new_player_joined, code})
        {:ok, {id, code}}

      :player_added_as_spectator ->
        {:player_added_as_spectator, {id, code}}

      response ->
        response
    end
  end

  @spec game_server_exists?(String.t()) :: boolean()
  def game_server_exists?(game_server) do
    case Registry.lookup(LudoEx.GameRegistry, game_server) do
      [] ->
        false

      [{_, nil}] ->
        true
    end
  end

  @spec get_players_count(String.t()) :: Integer.t()
  def get_players_count(game_server) do
    if game_server_exists?(game_server) do
      GenServer.call(via_tuple(game_server), {:get_games_player_count})
    else
      0
    end
  end

  @spec get_game_players(String.t()) :: List.t()
  def get_game_players(game_server) do
    GenServer.call(via_tuple(game_server), {:get_all_game_players})
  end

  def start_game_play(game_server) do
    GenServer.cast(via_tuple(game_server), {:game_start})
    PubSub.broadcast!(LudoEx.PubSub, "game:#{game_server}", {:game_started})
  end

  def get_active_game_player(game_server) do
    GenServer.call(via_tuple(game_server), {:get_active_player_id})
  end

  def make_player_move(game_server, player_id, player) do
    GenServer.cast(via_tuple(game_server), {:make_player_move, player_id, player})
    PubSub.broadcast!(LudoEx.PubSub, "game:#{game_server}", {:new_game_play_move, game_server})
  end

  def next_player_make_move(game_server, player_id) do
    GenServer.cast(via_tuple(game_server), {:next_player_move, player_id})
    :timer.sleep(2000)
    PubSub.broadcast(LudoEx.PubSub, "game:#{game_server}", {:new_game_play_move, game_server})
  end

  defp via_tuple(code), do: {:via, Registry, {LudoEx.GameRegistry, code}}

  defp validate_and_add_player_to_game(
         %GameState{state: :lobby_waiting, players: players} = state,
         %GamePlayer{id: id} = player
       ) do
    if Enum.count(players) < 4 do
      {:ok, Map.update(state, :players, %{}, &Map.put(&1, id, player))}
    else
      {:player_exceeded, state}
    end
  end

  defp validate_and_add_player_to_game(
         %GameState{state: :started, players: players} = state,
         %GamePlayer{id: id} = player
       ) do
    if Enum.count(players) < 4 do
      updated_player = Map.update(player, :is_player?, false, fn _ -> false end)

      {:spectator, Map.update(state, :players, %{}, &Map.put(&1, id, updated_player))}
    else
      {:player_exceeded, state}
    end
  end

  defp validate_and_add_player_to_game(
         %GameState{code: game_server, state: _, players: _players} = _state,
         _player
       ) do
    send(self(), {:terminate_child, game_server})
    :game_terminated
  end
end
