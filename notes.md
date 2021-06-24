# Ecto

## Repo

### Insert
```elixir
Repo.insert_all("artists", [[name: "John Coltrane"]])
Repo.insert_all("artists", [%{name: "John Coltrane"}])
Repo.insert_all("artists", [%{name: "John Coltrane"}, %{name: "Other Name"}])
```

### Query
```elixir
Repo.all(from a in "artists", select: a.name)
Repo.all(from a in "artists", select: [id: a.id, name: a.name])
Repo.all(from a in "artists", select: %{id: a.id, name: a.name})
```
