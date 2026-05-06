defmodule ServerProcess do
  def start(callback_module) do
    spawn(fn ->
      initial_state = callback_module.init()
      loop(callback_module, initial_state)
    end)
  end

  def call(server_pid, request) do
    send(server_pid, {:call, request, self()})

    receive do
      {:response, response} ->
        response
    end
  end

  def cast(server_pid, request) do
    send(server_pid, {:cast, request})
  end

  defp loop(callback_module, current_state) do
    receive do
      {:call, request, caller} ->
        {response, new_state} = callback_module.handle_call(request, current_state)
        send(caller, {:response, response})
        loop(callback_module, new_state)

      {:cast, request} ->
        new_state = callback_module.handle_cast(request, current_state)
        loop(callback_module, new_state)
    end
  end
end

defmodule TodoServer do
  def start do
    ServerProcess.start(TodoServer)
  end

  def init do
    TodoList.init()
  end

  def entries(pid, date) do
    ServerProcess.call(pid, {:entries, date})
  end

  def add_entry(pid, new_entry) do
    ServerProcess.cast(pid, {:add_entry, new_entry})
  end

  def delete_entry(pid, entry_id) do
    ServerProcess.cast(pid, {:delete_entry, entry_id})
  end

  def update_entry(pid, entry_id, updater_fun) do
    ServerProcess.cast(pid, {:update_entry, entry_id, updater_fun})
  end

  def handle_call({:entries, date}, todo_list) do
    entries = TodoList.entries(todo_list, date)
    {entries, todo_list}
  end

  def handle_cast({:add_entry, new_entry}, todo_list) do
    TodoList.add_entry(todo_list, new_entry)
  end

  def handle_cast({:delete_entry, entry_id}, todo_list) do
    TodoList.delete_entry(todo_list, entry_id)
  end

  def handle_cast({:update_entry, entry_id, updater_fun}, todo_list) do
    TodoList.update_entry(todo_list, entry_id, updater_fun)
  end
end

defmodule TodoList do
  defstruct next_id: 1, entries: %{}

  def init() do
    %TodoList{}
  end

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
