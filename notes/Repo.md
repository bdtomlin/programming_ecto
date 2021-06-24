# Ecto

## Repo

### Insert
You can use a list of keyword lists or a list of maps
```elixir
Repo.insert_all("artists", [[name: "John Coltrane"]])
Repo.insert_all("artists", [%{name: "John Coltrane"}])
Repo.insert_all("artists", [%{name: "John Coltrane"}, %{name: "Other Name"}])
Repo.insert_all("artists", [[name: "Sonny Rollins", inserted_at: DateTime.utc_now()]])
```

### Query
`select` is needed when not using schemas
```elixir
Repo.all(from a in "artists", select: a.name)
Repo.all(from a in "artists", select: [id: a.id, name: a.name])
Repo.all(from a in "artists", select: %{id: a.id, name: a.name})
```

### Update
Options available are `set`, `inc`,
`push`, `pull` are available to add and remove elements to array columns

```elixir
Repo.update_all("artists", set: [updated_at: DateTime.utc_now()])
Repo.all(from t in "tracks", select: [t.title, t.duration, t.index, t.number_of_plays])
Repo.update_all("tracks", inc: [number_of_plays: 2])
Repo.update_all("tracks", inc: [number_of_plays: -1])
Repo.all(from t in "tracks", select: [t.title, t.duration, t.index, t.number_of_plays])
```

### Delete
```elixir
Repo.delete_all("tracks")
```

### Getting values back with `returning`
The Repo's all functions return a tuple with the number of affected records and the value
we ask the database to return. The default is nil. ex: {31, nil}
```elixir
Repo.insert_all("artists", [%{name: "Max Roach"}, %{name: "Art Blakey"}], returning: [:id, :name])
```

### Queries
You can use sql with `Ecto.Adapters.SQL.query` or it's undocumented short cut `Repo.query`
```elixir
Ecto.Adapters.SQL.query(Repo, "select * from artists")
Repo.query("select * from artists")
```

### Aggregates
Options are `count`, `avg`, `min`, `max`, `sum`
```elixir
Repo.aggregate("albums", :count, :id)
```

### Customizing Your Repo
You can add functions to your Repo to add custom behaviour
```elixir
# add to Repo...
# def count(table) do
#   aggregate(table, :count, :id)
# end
Repo.count("albums")
```
You can also add stuff to the initialization by adding an init function to your Repo
```elixir
def init(_, opts) do
  {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
end
```

