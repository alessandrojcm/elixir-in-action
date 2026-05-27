defmodule TodoGenServer do
  use GenServer

  @impl true
  def init(_) do
    {:ok, TodoList.new()}
  end

  def start do
    GenServer.start(TodoGenServer, nil)
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
    {:reply, TodoList.entries(state, date), state}
  end

  @impl GenServer
  def handle_cast(request, state) do
    case request do
      {:delete, key} -> {:noreply, TodoList.delete_entry(state, key)}
      {:post, value} -> {:noreply, TodoList.add_entry(state, value)}
      {:put, key, updater_fun} -> {:noreply, TodoList.update_entry(state, key, updater_fun)}
    end
  end
end

defmodule TodoList do
  defstruct next_id: 1, entries: %{}

  def new(entries \\ []) do
    Enum.reduce(
      entries,
      %TodoList{},
      &add_entry(&2, &1)
    )
  end

  def add_entry(%TodoList{} = todo_list, entry) do
    entry = Map.put(entry, :id, todo_list.next_id)

    new_entries =
      Map.put(
        todo_list.entries,
        todo_list.next_id,
        entry
      )

    %TodoList{todo_list | entries: new_entries, next_id: todo_list.next_id + 1}
  end

  def entries(todo_list, date) do
    todo_list.entries
    |> Map.values()
    |> Enum.filter(fn entry -> entry.date == date end)
  end

  def update_entry(%TodoList{} = todo_list, entry_id, updater_fun) do
    case Map.fetch(todo_list.entries, entry_id) do
      :error ->
        todo_list

      {:ok, old_entry} ->
        new_entry = updater_fun.(old_entry)
        new_entries = Map.put(todo_list.entries, new_entry.id, new_entry)
        %TodoList{todo_list | entries: new_entries}
    end
  end

  def delete_entry(%TodoList{} = todo_list, entry_id) do
    case Map.fetch(todo_list.entries, entry_id) do
      :error ->
        todo_list

      {:ok} ->
        Map.filter(todo_list.entries, fn entry -> entry.id != entry_id end)
    end
  end
end
