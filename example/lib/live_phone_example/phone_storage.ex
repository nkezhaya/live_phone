defmodule LivePhoneExample.PhoneStorage do
  use Agent

  @name :phone_state

  def start_link(_) do
    Agent.start_link(fn -> nil end, name: @name)
  end

  def get_phone do
    Agent.get(@name, & &1)
  end

  def put_phone(phone) do
    Agent.update(@name, fn _ -> phone end)
  end
end
