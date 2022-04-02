defmodule LudoEx.GamePlayer do
  @moduledoc """
  Game Player is a Struct to get player name and the selected Game Play color
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias LudoEx.GameServer

  @game_play_colors ~w(red yellow blue green)a

  @player_pawns %{
    "0" => -1,
    "1" => -1,
    "2" => -1,
    "3" => -1
  }

  @game_code_range ?A..?Z

  @primary_key false
  embedded_schema do
    field :id, Ecto.UUID
    field :name, :string
    field :color, Ecto.Enum, values: @game_play_colors
    field :game_code, :string
    field :pawns, :map, default: @player_pawns
    field :can_make_move?, :boolean, default: false
    field :win_postion, :integer, default: 0
    field :dice_roll_positions, {:array, :integer}, default: []
    field :is_player?, :boolean, default: true
    field :can_roll_dice?, :boolean, default: false
  end

  def changeset(params) do
    %__MODULE__{}
    |> cast(params, __schema__(:fields))
    |> validate_required([:name])
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, __schema__(:fields))
    |> validate_required([:name])
    |> validate_game_server()
    |> choose_game_player_color()
    |> generate_player_id()
  end

  def new(params) do
    apply_action(create_changeset(params), :insert)
  end

  defp validate_game_server(changeset) do
    game_server_code = get_change(changeset, :game_code)

    with {:code_exists, code} when not is_nil(code) <-
           {:code_exists, get_change(changeset, :game_code)},
         true <- GameServer.game_server_exists?(code) do
      changeset
    else
      {:code_exists, nil} ->
        put_change(changeset, :game_code, generate_game_code())

      false ->
        add_error(
          changeset,
          :game_code,
          "Game Server #{game_server_code} - Doesn't exists, check your Game access code."
        )
    end
  end

  defp generate_game_code do
    Enum.reduce(1..6, "", fn _, code -> code <> <<Enum.random(@game_code_range)>> end)
  end

  defp generate_player_id(changeset) do
    id = Ecto.UUID.generate()
    put_change(changeset, :id, id)
  end

  defp choose_game_player_color(changeset) do
    game_server = get_change(changeset, :game_code)
    idx = GameServer.get_players_count(game_server)
    color = Enum.at(@game_play_colors, idx)
    put_change(changeset, :color, color)
  end
end
