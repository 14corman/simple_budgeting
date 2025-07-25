if Mix.env() == :dev do

  # Make sure that the postgresql-client library is installed
  "apk update && apk add --no-cache postgresql-client"
  |> String.to_charlist
  |> :os.cmd

  if File.exists?("postgres_sql.dump") do
    # Seed the database
    "PGPASSWORD=#{System.get_env("DATABASE_PASSWORD")} pg_restore --verbose --host db --username postgres --clean --if-exists --no-owner --no-acl --dbname simple_budgeting_dev postgres_sql.dump"
    |> String.to_charlist
    |> :os.cmd
    |> IO.puts
  end

end
