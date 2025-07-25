if Mix.env() == :dev do

  # Make sure that the postgresql-client library is installed
  "apk update && apk add --no-cache postgresql-client"
  |> String.to_charlist
  |> :os.cmd

  date =
    "America/New_York"
    |> DateTime.now!()
    |> Calendar.strftime("%d%b%Y")

  is_balanced = true

  file_suffix =
    if is_balanced do
      date
    else
      "#{date}_BALANCED"
    end

  # Seed the database
  "PGPASSWORD=#{System.get_env("DATABASE_PASSWORD")} pg_dump --verbose --host db --username postgres --clean -Fc simple_budgeting_dev > db_backups/postgres_sql_#{file_suffix}.dump"
  |> String.to_charlist
  |> :os.cmd
  |> IO.puts

end
