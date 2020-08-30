defmodule Crates.Player do
  defstruct x: 0, y: 0, facing: :right

  def new do
    %__MODULE__{}
  end
end
