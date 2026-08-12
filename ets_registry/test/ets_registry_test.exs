defmodule EtsRegistryTest do
  use ExUnit.Case
  doctest EtsRegistry

  setup do
    start_supervised!(EtsRegistry)
    start_supervised!({Registry, keys: :unique, name: :name})
    :ok
  end

  test "registers processes" do
    :ok = EtsRegistry.register(:name)
  end

  test "it should prevent duplicated processes" do
    :ok = EtsRegistry.register(:name)
    :error = EtsRegistry.register(:name)
  end

  test "it should find registered processes" do
    :ok = EtsRegistry.register(:name)
    assert is_pid(EtsRegistry.whereis(:name))
  end

  test "it should not find unregistered processes" do
    assert is_nil(EtsRegistry.whereis(:name))
  end

  test "it should automatically remove dead processes" do
    victim = spawn(fn -> Process.sleep(:infinity) end)
    Process.register(victim, :victim)

    :ok = EtsRegistry.register(:victim)
    assert EtsRegistry.whereis(:victim) == victim

    ref = Process.monitor(victim)
    Process.exit(victim, :kill)
    assert_receive {:DOWN, ^ref, :process, ^victim, _}

    assert :ok = wait_until_removed(:victim)
  end

  defp wait_until_removed(name, tries \\ 50)
  defp wait_until_removed(_name, 0), do: flunk("process was never removed from the registry")

  defp wait_until_removed(name, tries) do
    if is_nil(EtsRegistry.whereis(name)) do
      :ok
    else
      Process.sleep(10)
      wait_until_removed(name, tries - 1)
    end
  end
end
