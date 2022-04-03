defmodule LudoExWeb.GameViewHelpers do
  def player_pawns_in_home(active_players, player_color, index) do
    index = to_string(index)

    case Enum.filter(active_players, &(&1.color == player_color)) do
      [] ->
        nil

      [player] ->
        if player.pawns[index] === -1 do
          """
            <div class="pawn #{to_string(player_color)}-pawn">
              <div class="pawn-black"></div>
            </div>
          """
        end
    end
  end

  def player_pawns_in_cell(active_players, cell_index) do
    active_players
    |> Enum.reduce_while("", fn %LudoEx.GamePlayer{color: color, pawns: pawns}, acc ->
      if Enum.any?(pawns, fn {_, cell} -> cell == cell_index end) do
        acc = """
          <div class="pawn #{to_string(color)}-pawn">
            <div class="pawn-black"></div>
          </div>
        """

        {:halt, acc}
      else
        {:cont, acc}
      end
    end)
  end
end
