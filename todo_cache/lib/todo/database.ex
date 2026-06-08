defmodule Todo.Database do
  use GenServer

  @db_folder "./persist"

  def start do
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  def store(key, data) do
    GenServer.cast(__MODULE__, {:store, key, data})
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def init(_) do
    IO.puts("Starting databse with three workers")

    {:ok,
     %{
       0 => Todo.Database.Worker.start(@db_folder),
       1 => Todo.Database.Worker.start(@db_folder),
       2 => Todo.Database.Worker.start(@db_folder)
     }}
  end

  def handle_cast({:store, key, data}, state) do
    {:ok, worker} = Map.fetch!(state, chose_worker(key))
    IO.inspect("#{inspect(self())}: storing #{inspect(key)} in #{inspect(worker)}")
    GenServer.cast(worker, {:store, key, data})

    {:noreply, state}
  end

  def handle_call({:get, key}, _, state) do
    {:ok, worker} = Map.fetch!(state, chose_worker(key))
    IO.inspect("#{inspect(self())}: getting #{inspect(key)} from #{inspect(worker)}")
    result = GenServer.call(worker, {:get, key})

    {:reply, result, state}
  end

  defp chose_worker(key) do
    :erlang.phash2(key, 3)
  end
end
