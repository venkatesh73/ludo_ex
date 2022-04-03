defmodule LudoEx.GameState do
  @moduledoc """
  This module provides a Struct to handle Game level configurations ans Player game play state.
  """
  use Ecto.Schema

  import Ecto.Changeset

  @game_state ~w(lobby_waiting started terminated game_over)a

  @type t :: %__MODULE__{
          code: String.t(),
          state: :lobby_waiting | :started | :terminated | :game_over,
          players: map()
        }

  @primary_key false
  embedded_schema do
    field :code, :string
    field :state, Ecto.Enum, values: @game_state, default: :lobby_waiting
    field :players, :map, default: %{}
  end

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(params) do
    %__MODULE__{}
    |> cast(params, [:code, :state, :players])
    |> validate_required([:code, :state])
  end

  @spec new(map()) :: %__MODULE__{}
  def new(params) do
    apply_action!(changeset(params), :insert)
  end
end
