defmodule LivePhone.CountryTest do
  use ExUnit.Case
  alias LivePhone.Country
  doctest LivePhone.Country

  describe "returns list of countries as LivePhone.Country" do
    test "default, sorted by name" do
      countries = Country.list()
      first_country = List.first(countries)
      last_country = List.last(countries)

      assert %Country{code: "AF", name: "Afghanistan"} = first_country
      assert %Country{code: "AX", name: "Åland Islands"} = last_country
    end

    test "sorted by preference than name" do
      countries = Country.list(["US", "CA", "GB"])
      [us_country, ca_country, gb_country | countries] = countries
      first_country = List.first(countries)
      last_country = List.last(countries)

      assert %Country{code: "US", name: "United States of America (the)"} = us_country
      assert %Country{code: "CA", name: "Canada"} = ca_country

      assert %Country{
               code: "GB",
               name: "United Kingdom of Great Britain and Northern Ireland (the)"
             } = gb_country

      assert %Country{code: "AF", name: "Afghanistan"} = first_country
      assert %Country{code: "AX", name: "Åland Islands"} = last_country
    end
  end
end
