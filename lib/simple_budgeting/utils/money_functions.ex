defmodule SimpleBudgeting.Utils.MoneyFunctions do
  @moduledoc """
  Provides utiliy functions for the Money library to be used throughout website.
  """
  require Protocol
  Protocol.derive(Jason.Encoder, Money)

  @doc """
  When collecting money amounts from a form, this function is called to parse
  the String returned from the form into a Money object.
  """
  def parse_money_in_attrs!(attrs, key) do
    {:ok, money} =
      attrs
      |> Map.get(key)
      |> case do
        %Money{} = money -> {:ok, money}
        value -> Money.parse(value)
      end

    Map.put(attrs, key, money)
  end

  # def parse_money_in_attrs(attrs, key) do
  #   attrs
  #   |> Map.get_and_update!(key, fn
  #     %Money{} = money -> money
  #     cur ->
  #       new_value =
  #         cur
  #         |> case do
  #           nil -> "0.00"
  #           "" -> "0.00"
  #           val -> "#{val}"
  #         end
  #         |> Float.parse()
  #         |> case do
  #           :error -> 0.0
  #           {float, _} -> float
  #         end
  #         |> Kernel.*(100.00001)
  #         |> trunc()
  #         |> Money.new()

  #       {cur, new_value}
  #   end)
  #   |> elem(1)
  # end

  @doc """
  Currently there is no helper function to turn Money structs into floats.
  We cannot simply take the amount and divid it by 10 in case we are not
  working with USD. Here, we format the money into the proper string,
  then parse it.
  """
  def money_to_float(%Money{} = money) do
    money
    |> Money.to_string(separator: "", delimiter: ".", symbol: false)
    |> Float.parse()
    |> elem(0)
  end

  @doc """
  There is already a &Money.multiply/2 function, but it uses round.
  There are cases when we do not want to round because we do not want
  the ability to go over a set amount, but can go under it.
  """
  def multiply_with_percent(%Money{amount: amount, currency: cur}, percent) do
    Money.new(trunc(amount * percent), cur)
  end

  def average_amounts(amounts) when is_list(amounts) do
    {sum, count} = Enum.reduce(amounts, {Money.new(0), 0}, fn amount, {sum, count} ->
      sum = Money.add(amount, sum)
      count = count + 1
      {sum, count}
    end)

    if count != 0 do
      Money.divide(sum, count) |> List.first()
    else
      nil
    end
  end
end
