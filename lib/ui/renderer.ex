defmodule UI.Renderer do
  defstruct scale: 1.0,
            offsets: {0, 0},
            graph: nil,
            animations: []

  alias Scenic.ViewPort
  alias Scenic.Graph
  alias UI.{Animation, SpriteLibrary}
  import Scenic.Primitives

  @sprites SpriteLibrary.new(
             ground_gray: "/static/images/ground_06.png",
             player_up: "/static/images/player_02.png",
             player_up_1: "/static/images/player_03.png",
             player_up_2: "/static/images/player_04.png",
             player_right: "/static/images/player_11.png",
             player_right_1: "/static/images/player_12.png",
             player_right_2: "/static/images/player_13.png",
             player_down: "/static/images/player_23.png",
             player_down_1: "/static/images/player_24.png",
             player_down_2: "/static/images/player_01.png",
             player_left: "/static/images/player_14.png",
             player_left_1: "/static/images/player_15.png",
             player_left_2: "/static/images/player_16.png"
           )

  def init(map, viewport) do
    SpriteLibrary.load_all(@sprites)
    {scale, offsets} = scale_for_viewport(map, viewport)
    graph = render_level(map, scale, offsets)

    %__MODULE__{
      scale: scale,
      offsets: offsets,
      graph: graph
    }
  end

  defp scale_for_viewport(map, viewport) do
    {
      :ok,
      %ViewPort.Status{size: {width, height}}
    } = ViewPort.info(viewport)

    dimension =
      Stream.iterate(3, fn exp -> exp + 1 end)
      |> Stream.map(fn exp -> 2 |> :math.pow(exp) |> round() end)
      |> Enum.reduce_while(nil, fn n, best ->
        fits_map? = n * map.width <= width and n * map.height <= height

        if is_nil(best) or fits_map? do
          {:cont, n}
        else
          {:halt, best}
        end
      end)

    {
      dimension / 64,
      {
        div(width - map.width * dimension, 2),
        div(height - map.height * dimension, 2)
      }
    }
  end

  defp render_level(map, scale, offsets) do
    Graph.build()
    |> group(
      fn level ->
        Enum.reduce(0..(map.height - 1), level, fn y, y_level ->
          Enum.reduce(0..(map.width - 1), y_level, fn x, x_level ->
            rect(
              x_level,
              {64, 64},
              fill: SpriteLibrary.image(@sprites, :ground_gray),
              translate: {x * 64, y * 64}
            )
          end)
        end)
        |> rect(
          {64, 64},
          fill: SpriteLibrary.image(@sprites, :player_right),
          id: :player
        )
      end,
      id: :level,
      scale: scale,
      translate: offsets
    )
  end

  def animate(renderer, player, last_tick) do
    Enum.reduce(
      renderer.animations,
      %__MODULE__{renderer | animations: []},
      fn animation, r ->
        case animation.target do
          Crates.Player ->
            {graph, animations} =
              if Animation.finished?(animation, last_tick) do
                g = render_player(player, [], last_tick, r.graph)
                {g, r.animations}
              else
                a = [animation | r.animations]
                g = render_player(player, [animation], last_tick, r.graph)
                {g, a}
              end

            %__MODULE__{r | graph: graph, animations: animations}
        end
      end
    )
  end

  def start_move(renderer, old_player, current_player, last_tick) do
    animation =
      Animation.new(
        target: Crates.Player,
        from: {old_player.x, old_player.y},
        to: {current_player.x, current_player.y},
        start: last_tick
      )

    animations = [animation | renderer.animations]
    graph = render_player(current_player, animations, last_tick, renderer.graph)

    %__MODULE__{renderer | graph: graph, animations: animations}
  end

  defp render_player(player, animations, tick, graph) do
    animated =
      Enum.reduce(animations, player, fn animation, target ->
        Animation.animate(animation, target, tick)
      end)

    Graph.modify(
      graph,
      :player,
      &rect(
        &1,
        {64, 64},
        fill:
          SpriteLibrary.image(
            @sprites,
            String.to_existing_atom("player_#{animated.facing}")
          ),
        translate: {round(animated.x * 64), round(animated.y * 64)}
      )
    )
  end
end
