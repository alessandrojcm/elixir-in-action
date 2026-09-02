defmodule Todo.Database.Worker do
  use GenServer

  def start_link(db_folder) do
    IO.puts("Starting database worker")

    GenServer.start_link(
      __MODULE__,
      db_folder
    )
  end

  def store(worker_id, key, data) do
    GenServer.cast(worker_id, {:store, key, data})
  end

  def get(worker_id, key) do
    GenServer.call(worker_id, {:get, key})
  end

  @impl true
  def init(db_folder) do
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
          {:error, :enoent} -> nil
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
