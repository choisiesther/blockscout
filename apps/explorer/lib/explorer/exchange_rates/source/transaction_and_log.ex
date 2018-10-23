defmodule Explorer.ExchangeRates.Source.TransactionAndLog do
  @moduledoc """
  Adapter for calculating the market cap and total supply from logs and transactions
  while still getting other info like price in dollars and bitcoin from a secondary source
  """

  alias Explorer.ExchangeRates.{Source, Token}
  alias Explorer.Chain

  @behaviour Source

  @impl Source
  def fetch_exchange_rates do
    token_data =
      secondary_source().fetch_exchange_rates()
      |> elem(1)
      |> Enum.find(fn token -> token.symbol == Explorer.coin() end)
      |> build_struct

    {:ok, [token_data]}
  end

  defp build_struct(original_token) do
    %Token{
      available_supply: to_decimal(Chain.circulating_supply()),
      btc_value: original_token.btc_value,
      id: original_token.id,
      last_updated: original_token.last_updated,
      market_cap_usd: Decimal.mult(to_decimal(Chain.circulating_supply()), original_token.usd_value),
      name: original_token.name,
      symbol: original_token.symbol,
      usd_value: original_token.usd_value,
      volume_24h_usd: original_token.volume_24h_usd
    }
  end

  defp to_decimal(value) do
    Decimal.new(value)
  end

  @spec secondary_source() :: module()
  defp secondary_source do
    config(:secondary_source) || Explorer.ExchangeRates.Source.CoinMarketCap
  end

  @spec config(atom()) :: term
  defp config(key) do
    Application.get_env(:explorer, __MODULE__, [])[key]
  end
end