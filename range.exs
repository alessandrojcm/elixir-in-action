defmodule RangeDo do
  def range(from, to) when Kernel.is_integer(from) and Kernel.is_integer(to) and from < to do
    do_range(from, to, [to])
  end

  def range(from, to) do
    :error
  end

  defp do_range(from, to, list) when from < to do
    do_range(from, to-1, [to-1 | list])
  end

  defp do_range(from, to, list) when from == to do
    list
  end
end
