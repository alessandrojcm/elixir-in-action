defmodule LineLengths do
  def line_lengths!(path) do
    File.stream!(path)
    |> Stream.map(&String.replace(&1, "\r", ""))
    |> Stream.map(&String.replace(&1, "\n", ""))
    |> Stream.map(&String.length/1)
    |> Enum.to_list()
  end
end
