defmodule News.Util.RandomColor do
  # Quick and dirty port of https://github.com/davidmerfield/randomColor
  
  @color_bounds [
    {:monochrome, [0,360], [[0,0],[100,0]]},
    {:red, [-26,18], [[20,100],[30,92],[40,89],[50,85],[60,78],[70,70],[80,60],[90,55],[100,50]]},
    {:orange, [19,46], [[20,100],[30,93],[40,88],[50,86],[60,85],[70,70],[100,70]]},
    {:yellow, [47,62], [[25,100],[40,94],[50,89],[60,86],[70,84],[80,82],[90,80],[100,75]]},
    {:green, [63,178], [[30,100],[40,90],[50,85],[60,81],[70,74],[80,64],[90,50],[100,40]]},
    {:blue, [179, 257], [[20,100],[30,86],[40,80],[50,74],[60,60],[70,52],[80,44],[90,39],[100,35]]},
    {:purple, [258, 282], [[20,100],[30,87],[40,79],[50,70],[60,65],[70,59],[80,52],[90,45],[100,42]]},
    {:pink, [283, 334], [[20,100],[30,90],[40,86],[60,84],[80,80],[90,75],[100,73]]},
  ]
  @color_bounds_keys Enum.map(@color_bounds, &(elem(&1, 0)))

  defstruct hue: :random, luminosity: :random

  def get(state \\ %__MODULE__{}) do
    :random.seed(:erlang.now)
    state = if state.hue == :monochrome, do: %__MODULE__{state | luminosity: 0}, else: state
    hue = get_hue(state)
    saturation = get_saturation(hue, state)
    brightness = get_brightness(hue, saturation, state)
    get_color(hue, saturation, brightness)
  end

  defp define_color({color, hue_range, lower_bounds}) do
    s_min = lower_bounds |> List.first |> List.first
    s_max = lower_bounds |> List.last |> List.first
    b_min = lower_bounds |> List.last |> Enum.at(1)
    b_max = lower_bounds |> List.first |> Enum.at(1)
    %{
      color: color,
      lower_bounds: lower_bounds,
      hue_range: hue_range,
      saturation_range: [s_min, s_max],
      brightness_range: [b_min, b_max],
    }
  end

  defp get_hue(state) do
    range = get_hue_range(state.hue)
    hue = random_within(range)
    if hue < 0, do: 360 - hue, else: hue
  end
  defp get_hue_range(number) when is_integer(number) and number < 360 and number > 0, do: [number, number]
  defp get_hue_range(color) when color in @color_bounds_keys, do: elem(List.keyfind(@color_bounds, color, 0), 1)
  defp get_hue_range(_), do: [0, 334]
  defp get_hue_color_info(hue) when is_integer(hue) do
    hue = if hue >= 334 and hue <= 360, do: hue - 360, else: hue
    color = Enum.find(@color_bounds, nil, fn(color={_, [hue0, hue1], _}) -> hue >= hue0 and hue <= hue1 end)
    if color, do: define_color(color), else: nil
  end

  def get_saturation(hue, %__MODULE__{luminosity: l}) when is_integer(l), do: l
  def get_saturation(hue, state) do
    IO.puts inspect(hue) <> inspect(state)
    [s_min, s_max] = get_saturation_range(hue) # TODO
    range = case state.luminosity do
      :random -> [0, 100]
      :bright -> [55, s_max]
      :dark -> [s_max - 10, s_max]
      :light -> [s_min, 55]
    end
    random_within(range)
  end
  defp get_saturation_range(hue) do
    get_hue_color_info(hue).saturation_range
  end

  defp get_brightness(hue, saturation, state) do
    b_min = get_minimum_brightness(hue, saturation)
    b_max = 100
    range = case state.luminosity do
      :dark -> [b_min, b_min + 20]
      :light -> [(b_max + b_min)/2, b_max]
      :random -> [0, 100]
    end
    random_within(range)
  end

  defp get_minimum_brightness(hue, saturation) do
    lower_bounds = get_hue_color_info(hue).lower_bounds
    minimum = Enum.map(Enum.with_index(lower_bounds), fn({[s1, v1], index}) ->
      [s2, v2] = Enum.at(lower_bounds, index + 1) || [999999,999999]
      if s2 && v2 && saturation >= s1 and saturation <= s2 do
        m = (v2 - v1)/(s2 - s1)
        b = v1 - m*s1
        m*saturation + b
      end
    end)
    |> Enum.filter(fn(x) -> x != nil end)
    |> List.first
    minimum || 0
  end

  defp get_color(hue, saturation, brightness) do
    rgb = hsv_to_rgb(hue, saturation, brightness)
    dark = brightness < 65
    [hue: hue, saturation: saturation, brightness: brightness, rgb: rgb, dark: dark]
  end

  defp hsv_to_rgb(h, s, v) do
    h = if h == 0, do: 1, else: h
    h = if h == 360, do: 359, else: h
    h = h / 360
    s = s / 100
    v = v / 100
    h_i = trunc(h*6)
    f = h * 6 - h_i
    p = v * (1 - s)
    q = v * (1 - f*s)
    t = v * (1 - (1 - f)*s)
    r = 256
    g = 256
    b = 256

    [r,g,b] = case h_i do
      0 -> [v, t, p]
      1 -> [q, v, p]
      2 -> [p, v, t]
      3 -> [p, q, v]
      4 -> [t, p, v]
      5 -> [v, p, q]
    end
    [trunc(r*255), trunc(g*255), trunc(b*255)]
  end

  defp random_within([start, stop]) do
    trunc((start + :random.uniform)*(stop + 1 - start))
  end
end
