defmodule LongestLineLength do
  def longest_line_length!(path) do
    File.stream!(path)
    |> Stream.map(&String.trim(&1))
    |> Enum.map(&String.length/1)
    |> Enum.max()
  end
end
