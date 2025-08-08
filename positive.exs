defmodule Positive do
  def positive(list) do
    do_positive(list, [])
  end

  defp do_positive([head | tail], acc) when head > 0 do
    do_positive(tail, [head | acc])
  end

  defp do_positive([_ | tail], acc) do
    do_positive(tail, acc)
  end

  defp do_positive([], acc) do
    acc
  end
end
