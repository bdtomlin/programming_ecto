# Transactions

## Pass a function to `Repo.transaction`. It can be anonymous or a named function
```elixir
artist = %Artist{name: "Johnny Hodges"}
Repo.transaction(fn ->
  Repo.insert!(artist)
  Repo.insert!(Log.changeset_for_insert(artist))
end)
```

This will fail and the artist won't be added. Transactions are rolled back when an unhandled error
happens, and the error will bubble up from the transaction function. This is why the bang
functions are used here `insert!`

This means that only unhandled errors will trigger the rollback behavior a return value of {:error, value} from one of the operations won't.
```elixir
artist = %Artist{name: "Ben Webster"}
Repo.transaction(fn ->
  Repo.insert!(artist)
  Repo.insert!(nil)
end)
```

You can use `Repo.rollback` to customize the behavior. It will return {:error, value} where value is whatever
gets passed to the function.

```elixir
cs = change(%Artist{name: nil}) |> validate_required([:name])
Repo.transaction(fn ->
  case Repo.insert(cs) do
    {:ok, _artist} -> IO.puts("Artist insert succeeded")
    {:error, _value} -> Repo.rollback("Artist insert failed")
  end
  case Repo.insert(Log.changeset_for_insert(cs)) do
    {:ok, _log} -> IO.puts("Log insert succeeded")
    {:error, _value} -> Repo.rollback("Log insert failed")
  end
end)
```

You can keep db in sync with external resources. Stripe would be a good example!

Ecto has no knowledge of how our search engine works, so it would be impossible for it to roll back changes to the search engine. This means that you should run all of your database operations first, then run any non-database operations: you don’t want those to run until you’re sure the database operations succeeded.
```elixir
artist = %Artist{name: "Johnny Hodges"}
Repo.transaction(fn ->
 artist_record = Repo.insert!(artist)
 Repo.insert!(Log.changeset_for_insert(artist_record))
 SearchEngine.update!(artist_record)
end)
```

## `Ecto.Multi`
```elixir
alias Ecto.Multi

artist = %Artist{name: "Johnny Hodges"}
multi =
  Multi.new \
  |> Multi.insert(:artist, artist) \
  |> Multi.insert(:log, Log.changeset_for_insert(artist))
Repo.transaction(multi)
```

You can name each change and then use pattern matching to handle any issues
```elixir
alias Ecto.Multi

artist = Repo.get_by(Artist, name: "Johnny Hodges")
artist_changeset = Artist.changeset(artist, %{name: "John Cornelius Hodges"})
invalid_changeset = Artist.changeset(artist, %{name: nil})
multi =
  Multi.new \
  |> Multi.update(:artist, artist_changeset) \
  |> Multi.insert(:invalid, invalid_changeset)

Repo.transaction(multi)
case Repo.transaction(multi) do
  {:ok, _results} ->
    IO.puts("Operations were successful")
  {:error, :artist, changeset, _changes} ->
    IO.puts("Artist update failed")
    IO.inspect(changeset.errors)
  {:error, :invalid, changeset, _changes} ->
    IO.puts("Invalid operation failed")
    IO.inspect(changeset.errors)
end
```

Executing non-database operations with multi

With anonymous function
```elixir
alias Ecto.Multi

artist = %Artist{name: "Toshiko Akiyoshi"}
multi =
  Multi.new \
  |> Multi.insert(:artist, invalid_changeset) \
  |> Multi.insert(:log, Log.changeset_for_insert(artist)) \
  |> Multi.run(:search, fn _repo, changes ->
    SearchEngine.update(changes[:artist])
  end)

Repo.transaction(multi)
```

With named module and function
```elixir
alias Ecto.Multi

artist = %Artist{name: "Toshiko Akiyoshi"}
multi =
  Multi.new \
  |> Multi.insert(:artist, invalid_changeset) \
  |> Multi.insert(:log, Log.changeset_for_insert(artist)) \
  |> Multi.run(:search, SearchEngine, :update, ["extra argument"])

# use to_list to what is queued up for multi before it's sent to the db
Multi.to_list(multi)

Repo.transaction(multi)
```

