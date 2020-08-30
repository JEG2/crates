defmodule UI.Animation do
  defstruct target: nil, from: nil, to: nil, start: nil, duration: 250, cycle: 3

  def new(fields) do
    struct!(__MODULE__, fields)
  end

  def animate(animation, target, now) do
    if target.__struct__ == animation.target do
      percent = (now - animation.start) / animation.duration
      {x, y} = {move(animation, 0, percent), move(animation, 1, percent)}

      suffix =
        rem(
          round(
            animation.duration * percent /
              (animation.duration / animation.cycle)
          ),
          animation.cycle
        )

      facing = String.replace("#{target.facing}_#{suffix}", ~r{_0\z}, "")
      %{target | x: x, y: y, facing: facing}
    else
      target
    end
  end

  def finished?(animation, now) do
    animation.start + animation.duration <= now
  end

  defp move(animation, i, percent) do
    from = elem(animation.from, i)
    to = elem(animation.to, i)
    distance = to - from
    from + distance * percent
  end
end
