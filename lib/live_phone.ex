defmodule LivePhone do
  def is_valid?(phone) do
    with {:ok, parsed_phone} <- ExPhoneNumber.parse(phone, nil),
         true <- ExPhoneNumber.is_valid_number?(parsed_phone) do
      true
    else
      _ -> false
    end
  end

  def normalize(phone, country) do
    phone
    |> String.replace(~r/[^\d]/, "")
    |> ExPhoneNumber.parse(country)
    |> case do
      {:ok, result} ->
        result |> ExPhoneNumber.format(:e164)

      _ ->
        phone
    end
  end

  def emoji_for_country(nil), do: ""

  def emoji_for_country(country_code) do
    country_code
    |> String.upcase()
    |> String.to_charlist()
    |> Enum.map(&(&1 - 65 + 127_462))
    |> List.to_string()
  end
end
