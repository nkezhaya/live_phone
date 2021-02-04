defmodule LivePhone.Countries do
  @moduledoc """
  The `LivePhone.Countries` module can be used to list all known countries and return
  them ordered alphabetically, and optionally you can ensure your preferred countries
  are prepended to the list instead of mixed in with the rest.
  """

  alias ISO
  alias LivePhone.Country

  @doc """
  This function returns all known countries as `LivePhone.Country` structs,
  sorted alphabetically by country name.

  Optionally you can specify a list of preferred country codes, these will
  subsequently be prepended to the list.

  ```elixir
  # This will return everything alphabetically
  abc_countries = LivePhone.Countries.list_countries()

  # This will return it alphabetically as well, but push
  # the US and GB `LivePhone.Country` structs to the top
  # of the list.
  my_countries = LivePhone.Countries.list_countries(["US", "GB"])
  ```
  """
  @spec list_countries(list(String.t())) :: [Country.t()]
  def list_countries(preferred \\ []) when is_list(preferred) do
    preferred = preferred |> Enum.uniq() |> Enum.with_index()

    ISO.countries()
    |> Enum.map(&Country.from_iso/1)
    |> Enum.map(&set_preferred_flag(&1, preferred))
    |> Enum.sort(&sort_by_name/2)
    |> Enum.sort_by(&sort_by_preferred(&1, preferred), :desc)
  end

  @spec set_preferred_flag(Country.t(), list(String.t())) :: Country.t()
  defp set_preferred_flag(%Country{} = country, preferred) do
    preferred
    |> Enum.find(fn {value, _index} -> value == country.code end)
    |> case do
      nil -> country
      {_, _index} -> %{country | preferred: true}
    end
  end

  @spec sort_by_name(%{name: String.t()}, %{name: String.t()}) :: boolean()
  defp sort_by_name(%{name: name_1}, %{name: name_2}) do
    name_1 < name_2
  end

  @spec sort_by_preferred(Country.t(), list(String.t())) :: integer()
  defp sort_by_preferred(%Country{preferred: false}, _), do: 0

  defp sort_by_preferred(%Country{code: country_code}, preferred) do
    preferred
    |> Enum.find(fn {value, _index} -> value == country_code end)
    |> case do
      nil -> 0
      {_, index} -> length(preferred) - index
    end
  end
end
