defmodule LudoEx.GamePlayer do
  @moduledoc """
  This Module provides a Stuct to handle player level game state settings.
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

  @type t :: %__MODULE__{
          id: Ecto.UUID,
          name: String.t(),
          color: :red | :yellow | :blue | :green,
          game_code: String.t(),
          pawns: map(),
          can_make_move?: true | false,
          win_postion: integer(),
          dice_roll_positions: [integer()],
          is_player?: true | false,
          can_roll_dice?: true | false
        }

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
    field :play_index, :integer
  end

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(params) do
    %__MODULE__{}
    |> cast(params, __schema__(:fields))
    |> validate_required([:name])
  end

  @spec create_changeset(map()) :: Ecto.Changeset.t()
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, __schema__(:fields))
    |> validate_required([:name])
    |> validate_game_server()
    |> generate_player_id()
    |> choose_game_player_color()
    |> set_can_roll_dice()
    |> set_player_index()
  end

  @spec new(map()) :: {:ok, %__MODULE__{}} | {:error, Ecto.Changeset.t()}
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

  defp set_can_roll_dice(changeset) do
    game_server = get_change(changeset, :game_code)

    if GameServer.get_players_count(game_server) == 0 do
      put_change(changeset, :can_roll_dice?, true)
    else
      changeset
    end
  end

  defp set_player_index(changeset) do
    game_server = get_change(changeset, :game_code)
    idx = GameServer.get_players_count(game_server)
    put_change(changeset, :play_index, idx + 1)
  end
end
