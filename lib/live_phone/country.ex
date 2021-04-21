defmodule LivePhone.Country do
  @moduledoc """
  The `LivePhone.Country` struct holds minimal information about a country, but
  it should be enough data for `LivePhone` to work it's magic.
  """

  alias ExPhoneNumber.Metadata

  defstruct [:code, :name, :flag_emoji, :region_code, preferred: false]

  @type t() :: %__MODULE__{
          preferred: boolean(),
          flag_emoji: String.t(),
          region_code: String.t(),
          code: String.t(),
          name: String.t()
        }

  @doc ~S"""
  Converts the given `iso_country` tuple into a `LivePhone.Country` struct.

  ## Examples

      iex> ISO.countries() |> Map.to_list() |> Enum.find(fn {cc, _} -> cc == "SL" end) |> LivePhone.Country.from_iso()
      %LivePhone.Country{
        preferred: false,
        region_code: "232",
        flag_emoji: "🇸🇱",
        code: "SL",
        name: "Sierra Leone"
      }

      iex> LivePhone.Country.from_iso({"US", %{"name" => "United States"}})
      %LivePhone.Country{
        preferred: false,
        region_code: "1",
        flag_emoji: "🇺🇸",
        code: "US",
        name: "United States"
      }

  """
  @spec from_iso({String.t(), %{String.t() => String.t()}}) :: t()
  def from_iso({country_code, %{"name" => name}}) do
    %__MODULE__{
      region_code: find_region_code(country_code),
      flag_emoji: LivePhone.emoji_for_country(country_code),
      code: country_code,
      name: name
    }
  end

  @spec find_region_code(String.t()) :: String.t()
  defp find_region_code(country_code) do
    Metadata.get_for_region_code(country_code)
    |> case do
      nil -> ""
      code -> to_string(code.country_code)
    end
  end
end
