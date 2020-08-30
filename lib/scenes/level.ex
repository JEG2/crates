defmodule Crates.Scene.Level do
  use Scenic.Scene
  require Logger
  alias UI.{Clock, Renderer}

  defstruct game: nil,
            renderer: nil,
            clock: nil,
            moves: MapSet.new()

  def init(_, opts) do
    Logger.configure(level: :info)

    game = Crates.Game.new()
    renderer = Renderer.init(game.map, Keyword.fetch!(opts, :viewport))
    clock = Clock.init()

    {
      :ok,
      %__MODULE__{game: game, renderer: renderer, clock: clock},
      push: renderer.graph
    }
  end

  def handle_input({:key, {"W", :press, _modifiers}}, _context, state) do
    move(:up, state)
  end

  def handle_input({:key, {"D", :press, _modifiers}}, _context, state) do
    move(:right, state)
  end

  def handle_input({:key, {"S", :press, _modifiers}}, _context, state) do
    move(:down, state)
  end

  def handle_input({:key, {"A", :press, _modifiers}}, _context, state) do
    move(:left, state)
  end

  def handle_input({:key, {"W", :release, _modifiers}}, _context, state) do
    {
      :noreply,
      %__MODULE__{state | moves: MapSet.delete(state.moves, :up)}
    }
  end

  def handle_input({:key, {"D", :release, _modifiers}}, _context, state) do
    {
      :noreply,
      %__MODULE__{state | moves: MapSet.delete(state.moves, :right)}
    }
  end

  def handle_input({:key, {"S", :release, _modifiers}}, _context, state) do
    {
      :noreply,
      %__MODULE__{state | moves: MapSet.delete(state.moves, :down)}
    }
  end

  def handle_input({:key, {"A", :release, _modifiers}}, _context, state) do
    {
      :noreply,
      %__MODULE__{state | moves: MapSet.delete(state.moves, :left)}
    }
  end

  def handle_input(event, _context, state) do
    Logger.debug("Received event: #{inspect(event)}")
    {:noreply, state}
  end

  def handle_info(:tick, state) do
    if state.renderer.animations == [] do
      clock = Clock.update(state.clock)

      {:noreply, %__MODULE__{state | clock: clock}}
    else
      renderer =
        Renderer.animate(
          state.renderer,
          state.game.player,
          state.clock.last_tick
        )

      state = %__MODULE__{state | renderer: renderer}

      state =
        if renderer.animations == [] and MapSet.size(state.moves) == 1 do
          result =
            move(
              state.moves |> MapSet.to_list() |> hd(),
              %__MODULE__{state | moves: MapSet.new()}
            )

          elem(result, 1)
        else
          state
        end

      clock = Clock.update(state.clock)

      {:noreply, %__MODULE__{state | clock: clock}, push: renderer.graph}
    end
  end

  def handle_info(message, state) do
    Logger.debug("Unexpected message: #{inspect(message)}")
    {:noreply, state}
  end

  defp move(direction, state) do
    if MapSet.size(state.moves) == 0 do
      {moved?, new_game} =
        apply(
          Crates.Game,
          String.to_existing_atom("move_#{direction}"),
          [state.game]
        )

      if moved? do
        renderer =
          Renderer.start_move(
            state.renderer,
            state.game.player,
            new_game.player,
            state.clock.last_tick
          )

        {
          :noreply,
          %__MODULE__{
            state
            | game: new_game,
              renderer: renderer,
              moves: MapSet.put(state.moves, direction)
          },
          push: renderer.graph
        }
      else
        {:noreply, state}
      end
    else
      {
        :noreply,
        %__MODULE__{state | moves: MapSet.put(state.moves, direction)}
      }
    end
  end
end
