# Schema

## Basic
Using a schema handles the type conversion and select statement automatically
```elixir
track_id = "1"
q = from t in Track, where: t.id == ^track_id]
Repo.all(q)
Repo.one(q)
```

when using select all other fields are set to nil
```elixir
track_id = "1"
q = from t in Track, where: t.id == ^track_id, select: [:id, :title]
Repo.one(q)
```

## Insert
```elixir
Repo.insert(%Artist{name: "John Coltrane"})
# returns {:ok, Artist%{...}}
```

also works with nested relations

```elixir
Repo.insert(
  %Artist{
    name: "John Coltrane",
    albums: [
      %Album{
        title: "A Love Supreme"
      }
    ]
  }
)
```

You can use insert_all with schemas as well
```elixir
# returns {1, nil}
Repo.insert_all(Artist, [%{name: "John Coltrane"}])
# returns {1, [%MusicDB.Artist{...}]} with all fields
Repo.insert_all(Artist, [%{name: "John Coltrane"}], returning: true)
# returns {1, [%MusicDB.Artist{...}]} with all fields nil except those requested in returning
Repo.insert_all(Artist, [%{name: "John Coltrane"}], returning: [:id])
```

## Delete
A successful delete returns {:ok, struct}, the record has already been deleted at this point
```elixir
track = Repo.get_by(Track, title: "The Moontrane")
Repo.delete(track)
```

## Associations
Associations are not preloaded by default to avoid n+1 queries, they must be explicitly preloaded
```elixir
# preload in the initial query
Repo.all(from a in Album, preload: :tracks)
# or after the fact
Album
|> Repo.all
|> Repo.preload(:tracks)
```

nested preloading
```elixir
# preload in the initial query
Repo.one(from a in Artist, limit: 1, preload: [albums: :tracks])
# or after the fact
artist = Repo.one(from a in Artist, limit: 1)
artist = Repo.preload(artist, [albums: :tracks])
```

preload always uses 2 queries. If you want to get it in one query you need to add a join
```elixir
q =
  from a in Album,
  join: t in assoc(a, :tracks),
  where: t.title == "Freddie Freeloader",
  preload: [tracks: t]
Repo.all(q)
```

