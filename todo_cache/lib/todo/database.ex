defmodule Todo.Database do
  @pool_size 3
  @db_folder "./persist"

  def start_link do
    IO.puts("Starting database server")
    children = Enum.map(1..@pool_size, &worker_spec/1)
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def store(key, data) do
    :poolboy.transaction(
      __MODULE__,
      fn worker -> Todo.Database.Worker.store(worker, key, data) end
    )
  end

  def get(key) do
    :poolboy.transaction(
      __MODULE__,
      fn worker -> Todo.Database.Worker.get(worker, key) end
    )
  end

  def init(_) do
    IO.puts("Starting databse with three workers")
    {:ok, nil}
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

  def child_spec(_) do
    IO.puts("Starting database with #{@db_folder} workers")
    File.mkdir_p!(@db_folder)

    :poolboy.child_spec(
      __MODULE__,
      [
        name: {:local, __MODULE__},
        worker_module: Todo.Database.Worker,
        size: @pool_size
      ],
      [@db_folder]
    )
  end

  defp chose_worker(key) do
    :erlang.phash2(key, @pool_size) + 1
  end

  defp worker_spec(worker_id) do
    default_worker_spec = {Todo.Database.Worker, {worker_id, @db_folder}}
    Supervisor.child_spec(default_worker_spec, id: worker_id)
  end
end
