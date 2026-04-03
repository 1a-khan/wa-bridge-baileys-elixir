defmodule WaBridgeTest do
  use ExUnit.Case
  doctest WaBridge

  test "greets the world" do
    assert WaBridge.hello() == :world
  end
end
