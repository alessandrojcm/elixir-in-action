defmodule Todo.Database.Worker do
  use GenServer

  def start_link({worker_id, db_folder}) do
    IO.puts("Starting database worker")

    GenServer.start_link(
      __MODULE__,
      db_folder,
      name: via_tuple(worker_id)
    )
  end

  def store(worker_id, key, data) do
    GenServer.cast(via_tuple(worker_id), {:store, key, data})
  end

  def get(worker_id, key) do
    GenServer.call(via_tuple(worker_id), {:get, key})
  end

  @impl true
  def init(db_folder) do
    IO.puts("Starting database with #{db_folder}")
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

  defp via_tuple(worker_id) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, worker_id})
  end
end
