defmodule LudoEx.GameMoves do
  @moduledoc """
  This is Module helps to track down the each dice movement of all the teams.
  """
  alias LudoEx.GamePlayer
  alias LudoEx.GameServer

  @routes %{
    yellow: [
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
      24,
      25,
      26,
      27,
      28,
      29,
      30,
      31,
      32,
      33,
      34,
      35,
      36,
      37,
      38,
      39,
      40,
      41,
      42,
      43,
      44,
      45,
      46,
      47,
      48,
      49,
      50,
      51,
      52,
      1,
      2,
      60,
      61,
      62,
      63,
      64,
      65
    ],
    blue: [
      17,
      18,
      19,
      20,
      21,
      22,
      23,
      24,
      25,
      26,
      27,
      28,
      29,
      30,
      31,
      32,
      33,
      34,
      35,
      36,
      37,
      38,
      39,
      40,
      41,
      42,
      43,
      44,
      45,
      46,
      47,
      48,
      49,
      50,
      51,
      52,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      70,
      71,
      72,
      73,
      74,
      75
    ],
    red: [
      30,
      31,
      32,
      33,
      34,
      35,
      36,
      37,
      38,
      39,
      40,
      41,
      42,
      43,
      44,
      45,
      46,
      47,
      48,
      49,
      50,
      51,
      52,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
      24,
      25,
      26,
      27,
      28,
      80,
      81,
      82,
      83,
      84,
      85
    ],
    green: [
      43,
      44,
      45,
      46,
      47,
      48,
      49,
      50,
      51,
      52,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
      17,
      18,
      19,
      20,
      21,
      22,
      23,
      24,
      25,
      26,
      27,
      28,
      29,
      30,
      31,
      32,
      33,
      34,
      35,
      36,
      37,
      38,
      39,
      40,
      41,
      90,
      91,
      92,
      93,
      94,
      95
    ]
  }

  # @safe_house [4, 17, 30, 43, 12, 25, 30, 38, 43, 51]

  def player_dice_move(
        game_server,
        %GamePlayer{id: id, color: color, can_roll_dice?: true, pawns: pawns} = player,
        _pawn \\ 0
      ) do
    # Players no Pawns are out Yet -
    # Roll the Dice if value is other than 6, Just Ignore and make the Next player move
    # If the value is 6, release the 1 pawn out of Home and wait for another dice roll
    # Players only one pawns are out -
    # Roll the dice, if the value is other than 6, make the one pawn move and Next player move
    # If the value is 6, wait for user to select the pawn (if the selected is not from house, make the move, else make the pawn move from house to play) and wait for another dice roll

    dice_value = roll_dice()

    if dice_value !== 6 && !Enum.all?(pawns, fn {_, value} -> value === -1 end) do
      IO.inspect("---- Dice not 6 and atleast one pawn is outside -----")
      Task.start(GameServer, :next_player_make_move, [game_server, id])
    end

    if dice_value !== 6 && Enum.all?(pawns, fn {_, value} -> value === -1 end) do
      IO.inspect("---- Dice not 6 and no pawn is outside -----")
      Task.start(GameServer, :next_player_make_move, [game_server, id])
    end

    if dice_value === 6 && Enum.all?(pawns, fn {_, value} -> value === -1 end) do
      IO.inspect("---- Dice 6 and no pawn is outside -----")
      Task.start(GameServer, :next_player_make_move, [game_server, id])
    end

    if dice_value === 6 && !Enum.all?(pawns, fn {_, value} -> value === -1 end) do
      IO.inspect("---- Dice 6 and alteast one pawn is outside -----")
      Task.start(GameServer, :next_player_make_move, [game_server, id])
    end

    dice_value
  end

  def roll_dice do
    Enum.random(1..6)
  end
end
