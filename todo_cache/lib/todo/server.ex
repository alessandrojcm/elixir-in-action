defmodule Todo.Server do
  use GenServer

  @impl true
  def init(name) do
    {:ok, {name, nil}, {:continue, :init}}
  end

  @impl true
  def handle_continue(:init, {name, nil}) do
    todo_list = Todo.Database.get(name) || Todo.List.new()

    {:noreply, {name, todo_list}}
  end

  def start_link(name) do
    GenServer.start_link(Todo.Server, name)
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
  def handle_call({:get, date}, _, {name, list}) do
    {:reply, Todo.List.entries(list, date), {name, list}}
  end

  @impl GenServer
  def handle_cast(request, state) do
    {name, todo_list} = state

    case request do
      {:delete, key} ->
        new_list = Todo.List.delete_entry(todo_list, key)
        Todo.Database.store(name, new_list)
        {:noreply, {name, new_list}}

      {:post, value} ->
        new_list = Todo.List.add_entry(todo_list, value)
        Todo.Database.store(name, new_list)
        {:noreply, {name, new_list}}

      {:put, key, updater_fun} ->
        new_list = Todo.List.update_entry(todo_list, key, updater_fun)
        Todo.Database.store(name, new_list)
        {:noreply, {name, new_list}}
    end
  end
end
