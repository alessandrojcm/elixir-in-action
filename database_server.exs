defmodule DatabaseServer do
  def start do
    spawn(fn ->
      initial_state = :rand.uniform(1000)
      loop(initial_state)
    end)
  end

  defp loop(state) do
    receive do
      {:run_query, caller, query_def} ->
        query_result = run_query(state, query_def)
        send(caller, {:query_result, query_result})
    end

    loop(state)
  end

  def run_async(server_pid, query_def) do
    send(server_pid, {:run_query, self(), query_def})
  end

  def get_result do
    receive do
      {:query_result, result} -> result
    after
      5000 -> {:error, :timeout}
    end
  end

  defp run_query(state, query_def) do
    Process.sleep(2000)
    "Connection #{state}: #{query_def} result"
  end
end
