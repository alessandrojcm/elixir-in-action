defmodule LongestLine do
  def longest_line!(path) do
    File.stream!path()
    |> Stream.map(&String.trim/1)
    |> Enum.max_by(&String.length/1)
  end
end
