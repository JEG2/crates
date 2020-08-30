defmodule UI.Clock do
  defstruct last_tick: nil,
            start_of_second: nil,
            ticks_this_second: 0

  require Logger

  @ms_per_tick div(1_000, 30)

  def init() do
    Process.send_after(self(), :tick, @ms_per_tick)
    now = System.monotonic_time(:millisecond)
    %__MODULE__{last_tick: now, start_of_second: now}
  end

  def update(clock) do
    fps = clock.ticks_this_second + 1
    now = System.monotonic_time(:millisecond)

    {ticks_this_second, start_of_second} =
      if now - clock.start_of_second >= 1_000 do
        Logger.debug("FPS: #{fps}")
        {0, now}
      else
        {clock.ticks_this_second + 1, clock.start_of_second}
      end

    ms_to_next_tick =
      case @ms_per_tick - (now - clock.last_tick) do
        ms when ms > 0 -> ms
        _overage -> @ms_per_tick
      end

    Process.send_after(self(), :tick, ms_to_next_tick)

    %__MODULE__{
      clock
      | last_tick: now,
        start_of_second: start_of_second,
        ticks_this_second: ticks_this_second
    }
  end
end
