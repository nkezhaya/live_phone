defmodule LivePhone.Countries do
  alias ISO

  alias LivePhone.Country

  def list_countries(preferred \\ []) when is_list(preferred) do
    preferred = preferred |> Enum.uniq() |> Enum.with_index()

    ISO.countries()
    |> Enum.map(&Country.from_iso/1)
    |> Enum.map(&set_preferred_flag(&1, preferred))
    |> Enum.sort(&sort_by_name/2)
    |> Enum.sort_by(&sort_by_preferred(&1, preferred), :desc)
  end

  defp set_preferred_flag(%Country{} = country, preferred) do
    preferred
    |> Enum.find(fn {value, _index} -> value == country.code end)
    |> case do
      nil -> country
      {_, _index} -> %{country | preferred: true}
    end
  end

  defp sort_by_name(%{name: name_1}, %{name: name_2}) do
    name_1 < name_2
  end

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
