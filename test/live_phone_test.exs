defmodule LivePhoneTest do
  use ExUnit.Case
  doctest LivePhone

  test "greets the world" do
    assert LivePhone.hello() == :world
  end
end
