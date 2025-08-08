defmodule LenList do
  def list_len(list) do
    do_get_len_list(0, list)
  end

  defp do_get_len_list(size, []) do
    size
  end

  defp do_get_len_list(size, [_|tail]) do
    do_get_len_list(size+1, tail)
  end
end
