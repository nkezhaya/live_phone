defmodule LivePhone.Country do
  alias ExPhoneNumber.Metadata

  defstruct [:code, :name, :flag_emoji, :region_code, preferred: false]

  def from_iso({country_code, %{"name" => name}}) do
    %__MODULE__{
      region_code: find_region_code(country_code),
      flag_emoji: LivePhone.emoji_for_country(country_code),
      code: country_code,
      name: name
    }
  end

  defp find_region_code(country_code) do
    Metadata.get_for_region_code(country_code)
    |> case do
      nil -> ""
      code -> to_string(code.country_code)
    end
  end
end
