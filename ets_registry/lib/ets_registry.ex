defmodule EtsRegistry do
  use GenServer
  @table_name :ets_registry

  def start_link(_opts \\ nil) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    Process.flag(:trap_exit, true)
    {:ok, :ets.new(@table_name, [:named_table, :public])}
  end

  def handle_info({:EXIT, pid, _}, state) do
    :ets.match_delete(state, {:_, pid})
    {:noreply, state}
  end

  def register(name) do
    GenServer.call(__MODULE__, {:register, name})
  end

  def whereis(name) do
    GenServer.call(__MODULE__, {:whereis, name})
  end

  def handle_call({:register, name}, _, state) do
    linked_pid = Process.whereis(name)

    if linked_pid == nil do
      {:reply, :error, state}
    else
      case :ets.insert_new(state, {name, linked_pid}) do
        false ->
          {:reply, :error, state}

        true ->
          Process.link(linked_pid)
          :ets.insert(state, {name, linked_pid})
          {:reply, :ok, state}
      end
    end
  end

  def handle_call({:whereis, name}, _, state) do
    case :ets.lookup(state, name) do
      [{^name, pid}] ->
        {:reply, pid, state}

      [] ->
        {:reply, nil, state}
    end
  end
end
