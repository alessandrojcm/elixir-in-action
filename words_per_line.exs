defmodule WordsPerLine do
  def words_per_line!(path) do
    File.stream!(path)
    |> Stream.map(&String.trim/1)
    |> Stream.map(&String.split/1)
    |> Stream.map(&length/1)
    |> Enum.to_list()
  end
end
