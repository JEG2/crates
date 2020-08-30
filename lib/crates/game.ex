defmodule Crates.Game do
  defstruct player: Crates.Player.new(), map: Crates.Map.new()

  def new do
    %__MODULE__{}
  end

  def move_up(game) do
    new_player_y = Enum.max([0, game.player.y - 1])

    {
      game.player.y != new_player_y or game.player.facing != :up,
      %__MODULE__{
        game
        | player: %Crates.Player{game.player | y: new_player_y, facing: :up}
      }
    }
  end

  def move_right(game) do
    new_player_x = Enum.min([game.map.width - 1, game.player.x + 1])

    {
      game.player.x != new_player_x or game.player.facing != :right,
      %__MODULE__{
        game
        | player: %Crates.Player{game.player | x: new_player_x, facing: :right}
      }
    }
  end

  def move_down(game) do
    new_player_y = Enum.min([game.map.height - 1, game.player.y + 1])

    {
      game.player.y != new_player_y or game.player.facing != :down,
      %__MODULE__{
        game
        | player: %Crates.Player{game.player | y: new_player_y, facing: :down}
      }
    }
  end

  def move_left(game) do
    new_player_x = Enum.max([0, game.player.x - 1])

    {
      game.player.x != new_player_x or game.player.facing != :left,
      %__MODULE__{
        game
        | player: %Crates.Player{game.player | x: new_player_x, facing: :left}
      }
    }
  end
end
