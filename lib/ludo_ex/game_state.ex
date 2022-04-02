defmodule LudoEx.GameState do
  @moduledoc """
  Game state is a Struct which provides an Player level configuration
  """
  use Ecto.Schema

  import Ecto.Changeset

  @game_state ~w(lobby_waiting started terminated game_over)a

  @primary_key false
  embedded_schema do
    field :code, :string
    field :state, Ecto.Enum, values: @game_state, default: :lobby_waiting
    field :players, :map, default: %{}
  end

  def changeset(params) do
    %__MODULE__{}
    |> cast(params, [:code, :state, :players])
    |> validate_required([:code, :state])
  end

  def new(params) do
    {:ok, game_state} = apply_action(changeset(params), :insert)
    game_state
  end
end
