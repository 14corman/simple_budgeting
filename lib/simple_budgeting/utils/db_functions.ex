defmodule SimpleBudgeting.Utils.DBFunctions do
  @moduledoc """
  Provides utiliy functions for the Money library to be used throughout website.
  """

  @base_path "db_backups"
  @base_dump_file_name "postgres_sql_?.dump"
  @date_parse_regex ~r/postgres_sql_(\d{2}\w{3}\d{4}).*/
  @date_part_regex ~r/(\d{2})(\w{3})(\d{4})/

  def dump_db(file_suffix, year) do
    # Make sure that the postgresql-client library is installed
    "apk update && apk add --no-cache postgresql-client"
    |> String.to_charlist
    |> :os.cmd

    path = "#{@base_path}/#{year}"
    file_name = String.replace(@base_dump_file_name, "?", file_suffix)

    case File.mkdir_p(path) do
      :ok ->
        # Seed the database
        "PGPASSWORD=#{System.get_env("DATABASE_PASSWORD")} pg_dump --verbose --host db --username postgres --clean -Fc simple_budgeting_dev > #{path}/#{file_name}"
        |> String.to_charlist
        |> :os.cmd
        |> then(&to_string/1)
        |> then(& String.contains?(&1, "error") || String.contains?(&1, "fail") || String.contains?(&1, "can't"))
        |> if do
          :dump_error
        else
          :ok
        end
      _ -> :make_file_error
    end
  end

  def restore_db(file_name, year) do
    # Make sure that the postgresql-client library is installed
    "apk update && apk add --no-cache postgresql-client"
    |> String.to_charlist
    |> :os.cmd

    path = "#{@base_path}/#{year}"

    if File.exists?("#{path}/#{file_name}") do
      # Seed the database
      "PGPASSWORD=#{System.get_env("DATABASE_PASSWORD")} pg_restore --verbose --host db --username postgres --clean --if-exists --no-owner --no-acl --dbname simple_budgeting_dev #{path}/#{file_name}"
      |> String.to_charlist
      |> :os.cmd
      |> then(&to_string/1)
      |> then(& String.contains?(&1, "error") || String.contains?(&1, "fail") || String.contains?(&1, "can't"))
      |> if do
        :restore_error
      else
        :ok
      end
    else
      :file_exists_error
    end
  end

  def find_dump_files!() do
    @base_path
    |> File.ls!()
    |> Enum.flat_map(fn year_dir ->
      "#{@base_path}/#{year_dir}"
      |> File.ls!()
      |> Enum.map(& build_file_map!(&1, year_dir))
    end)
    |> Enum.sort_by(& &1.date, Date)
  end

  def date_to_string(date) do
    date
    |> DateTime.new!(~T[05:00:00.000], "Etc/UTC")
    |> Calendar.strftime("%d%b%Y")
  end

  def string_to_date(str) do
    [_, day, month, year] = Regex.run(@date_part_regex, str)
    {day, _} = Integer.parse(day)
    {year, _} = Integer.parse(year)
    month = month_str_to_int(month)
    Date.new!(year, month, day)
  end

  defp build_file_map!(file_name, year_dir) do
    is_balanced = String.contains?(file_name, "BALANCED")
    [_, date] = Regex.run(@date_parse_regex, file_name)
    date = string_to_date(date)
    %{
      date: date,
      is_balanced: is_balanced,
      year_dir: year_dir,
      file_name: file_name,
    }
  end

  defp month_str_to_int("Jan"), do: 1
  defp month_str_to_int("Feb"), do: 2
  defp month_str_to_int("Mar"), do: 3
  defp month_str_to_int("Apr"), do: 4
  defp month_str_to_int("May"), do: 5
  defp month_str_to_int("Jun"), do: 6
  defp month_str_to_int("Jul"), do: 7
  defp month_str_to_int("Aug"), do: 8
  defp month_str_to_int("Sep"), do: 9
  defp month_str_to_int("Oct"), do: 10
  defp month_str_to_int("Nov"), do: 11
  defp month_str_to_int("Dec"), do: 12
end
