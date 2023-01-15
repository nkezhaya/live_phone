defmodule LivePhone.Country do
  @moduledoc """
  The `LivePhone.Country` struct holds minimal information about a country, but
  it should be enough data for `LivePhone` to work its magic.
  """

  alias ExPhoneNumber.Metadata
  alias ExPhoneNumber.Model.PhoneNumber

  @enforce_keys [:code, :name, :flag_emoji, :region_code]
  defstruct [:code, :name, :flag_emoji, :region_code, preferred: false]

  @type phone() :: %PhoneNumber{}
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
    case Metadata.get_for_region_code(country_code) do
      nil -> ""
      code -> to_string(code.country_code)
    end
  end

  @doc """
  This function returns all known countries as `LivePhone.Country` structs,
  sorted alphabetically by country name.

  Optionally you can specify a list of preferred country codes, and these will
  be put at the top of the list.

  ```elixir
  # This will return everything alphabetically
  abc_countries = LivePhone.Country.list()

  # This will return it alphabetically as well, but push
  # the US and GB `LivePhone.Country` structs to the top
  # of the list.
  my_countries = LivePhone.Country.list(["US", "GB"])
  ```
  """
  @spec list([String.t()]) :: [t()]
  def list(preferred \\ []) when is_list(preferred) do
    preferred = preferred |> Enum.uniq() |> Enum.with_index()

    ISO.countries()
    |> Enum.map(fn country ->
      country
      |> from_iso()
      |> set_preferred_flag(preferred)
    end)
    |> Enum.filter(&(&1.region_code && &1.region_code != ""))
    |> Enum.sort_by(& &1.name)
    |> Enum.sort_by(&sort_by_preferred(&1, preferred), :desc)
  end

  @doc """
  This function will retrieve a `Country` by its country code. Also accepts a
  `%PhoneNumber{}` struct.

  ## Examples

  ```elixir
    iex> LivePhone.Country.get("US")
    {:ok, %LivePhone.Country{code: "US", flag_emoji: "🇺🇸", name: "United States of America (the)", preferred: false, region_code: "1"}}

    iex> LivePhone.Country.get("FAKE")
    {:error, :not_found}

  ```
  """
  @spec get(%PhoneNumber{} | String.t()) :: {:ok, t()} | {:error, :not_found}
  def get(%PhoneNumber{} = phone) do
    phone
    |> ExPhoneNumber.Metadata.get_region_code_for_number()
    |> do_get()
  end

  def get(country_code) do
    do_get(country_code)
  end

  defp do_get(country_code) do
    list()
    |> Enum.find(&(&1.code == country_code))
    |> case do
      nil -> {:error, :not_found}
      country -> {:ok, country}
    end
  end

  @spec set_preferred_flag(t(), list(String.t())) :: t()
  defp set_preferred_flag(%__MODULE__{} = country, preferred) do
    preferred
    |> Enum.find(fn {value, _index} -> value == country.code end)
    |> case do
      nil -> country
      {_, _index} -> %{country | preferred: true}
    end
  end

  @spec sort_by_preferred(t(), list(String.t())) :: integer()
  defp sort_by_preferred(%__MODULE__{preferred: false}, _), do: 0

  defp sort_by_preferred(%__MODULE__{code: country_code}, preferred) do
    preferred
    |> Enum.find(fn {value, _index} -> value == country_code end)
    |> case do
      nil -> 0
      {_, index} -> length(preferred) - index
    end
  end
end
