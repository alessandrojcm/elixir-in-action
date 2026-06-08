defmodule Todo.Database.Worker do
  use GenServer

  def start(db_folder) do
    GenServer.start(Todo.Database.Worker, db_folder)
  end

  def store(key, data) do
    GenServer.cast(Todo.Database.Worker, {:store, key, data})
  end

  def get(key) do
    GenServer.call(Todo.Database.Worker, {:get, key})
  end

  @impl true
  def init(db_folder) do
    File.mkdir_p!(db_folder)
    {:ok, db_folder}
  end

  @impl GenServer
  def handle_cast({:store, key, data}, state) do
    IO.inspect("Serving cast from from worker #{inspect(self())}")

    spawn(fn ->
      key
      |> file_name(state)
      |> File.write!(:erlang.term_to_binary(data))
    end)

    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:get, key}, caller, state) do
    IO.inspect("Serving call from #{inspect(caller)} from worker #{inspect(self())}")

    spawn(fn ->
      IO.inspect("Spawning read process")

      data =
        case File.read(file_name(key, state)) do
          {:ok, contents} -> :erlang.binary_to_term(contents)
          _ -> nil
        end

      IO.inspect("Replying to #{inspect(caller)}")
      GenServer.reply(caller, data)
    end)

    {:noreply, state}
  end

  defp file_name(key, db_folder) do
    Path.join(db_folder, to_string(key))
  end
end
