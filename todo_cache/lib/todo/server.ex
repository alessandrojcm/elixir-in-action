defmodule Todo.Server do
  use GenServer

  @impl true
  def init(_) do
    {:ok, Todo.List.new()}
  end

  def start do
    GenServer.start(Todo.Server, nil)
  end

  def add_entry(pid, value) do
    GenServer.cast(pid, {:post, value})
  end

  def update_entry(pid, key, updater_fun) do
    GenServer.cast(pid, {:put, key, updater_fun})
  end

  def entries(pid, date) do
    GenServer.call(pid, {:get, date})
  end

  def delete_entry(pid, key) do
    GenServer.cast(pid, {:delete, key})
  end

  @impl GenServer
  def handle_call({:get, date}, _, state) do
    {:reply, Todo.List.entries(state, date), state}
  end

  @impl GenServer
  def handle_cast(request, state) do
    case request do
      {:delete, key} -> {:noreply, Todo.List.delete_entry(state, key)}
      {:post, value} -> {:noreply, Todo.List.add_entry(state, value)}
      {:put, key, updater_fun} -> {:noreply, Todo.List.update_entry(state, key, updater_fun)}
    end
  end
end
