defmodule LivePhone do
  @external_resource "./README.md"
  @moduledoc """
  #{File.read!(@external_resource)}
  """

  @doc ~S"""
  This is used to verify a given `phone` number and see if it is a valid
  number according to ExPhoneNumber.

  ## Examples

      iex> LivePhone.is_valid?("")
      false

      iex> LivePhone.is_valid?("+1555")
      false

      iex> LivePhone.is_valid?("+1555")
      false

      iex> LivePhone.is_valid?("+1 (555) 555-1234")
      false

      iex> LivePhone.is_valid?("+1 (555) 555-1234")
      false

      iex> LivePhone.is_valid?("+1 (650) 253-0000")
      true

      iex> LivePhone.is_valid?("+16502530000")
      true

  """
  def is_valid?(phone) do
    with {:ok, parsed_phone} <- ExPhoneNumber.parse(phone, nil),
         true <- ExPhoneNumber.is_valid_number?(parsed_phone) do
      true
    else
      _ -> false
    end
  end

  @doc ~S"""
  This is used to normalize a given `phone` number to E.164 format,
  and immediately return the value whether it is formatted or not.

  ## Examples

      iex> LivePhone.normalize!("1234", nil)
      "1234"

      iex> LivePhone.normalize!("+1 (650) 253-0000", "US")
      "+16502530000"

  """
  def normalize!(phone, country) do
    phone
    |> normalize(country)
    |> case do
      {:ok, formatted} -> formatted
      {:error, unformatted} -> unformatted
    end
  end

  @doc ~S"""
  This is used to normalize a given `phone` number to E.164 format,
  and returns a tuple with `{:ok, formatted_phone}` for valid numbers
  and `{:error, unformatted_phone}` for invalid numbers.

  ## Examples

      iex> LivePhone.normalize("1234", nil)
      {:error, "1234"}

      iex> LivePhone.normalize("+1 (650) 253-0000", "US")
      {:ok, "+16502530000"}

  """
  def normalize(phone, country) do
    phone
    |> String.replace(~r/[^\d]/, "")
    |> ExPhoneNumber.parse(country)
    |> case do
      {:ok, result} ->
        {:ok, result |> ExPhoneNumber.format(:e164)}

      _ ->
        {:error, phone}
    end
  end

  @doc ~S"""
  Parses the given `country_code` into an emoji, but I should
  note that the emoji is not validated so it might return an
  invalid emoji (this will also depend on the unicode version
  supported by your operating system, and which flags are included.)

  ## Examples

      iex> LivePhone.emoji_for_country(nil)
      ""

      iex> LivePhone.emoji_for_country("US")
      "🇺🇸"

  """
  def emoji_for_country(nil), do: ""

  def emoji_for_country(country_code) do
    country_code
    |> String.upcase()
    |> String.to_charlist()
    |> Enum.map(&(&1 - 65 + 127_462))
    |> List.to_string()
  end
end
