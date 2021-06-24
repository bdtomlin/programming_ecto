# Query

## Syntaxes

### Keyword syntax (most common and succinct, prefer this syntax)
```elixir
    query = from t in "tracks",
      join: a in "albums",
      on: t.album_id == a.id,
      where: t.duration > 900,
      select: [t.id, t.title, a.title]
```

### Macro syntax
```elixir
query =
  "tracks"
  |> join(:inner, [t], a in "albums", on: t.album_id == a.id)
  |> where([t,a], t.duration > 900)
  |> select([t,a], [t.id, t.title, a.title])
```

## Example
You can use `Ecto.Adapters.SQL.to_sql(:all, Repo, query)` or it's undocumented shortcut
`Repo.to_sql(:all, query)`
`to_sql` takes 3 options: `all`, `delete_all`, or `update_all`
```elixir
  query = Ecto.Query.from "artists", select: [:name]
  query = from "artists", select: [:name]
  Repo.to_sql(:all, query)
  Ecto.Adapters.SQL.to_sql(:all, Repo, query)
  Repo.all(query)
```

## Prefixes (multi-schema)
```elixir
  query = from "artists", prefix: "public", select: [:name]
```

## Where
```elixir
  q = from "artists", where: [name: "Bill Evans"], select: [:id, :name]
```

## Pin operator to avoid sql injection
```elixir
  name = "Bill Evans"
  q = from "artists", where: [name: ^name], select: [:id, :name]
```
The Pin operator can also surround a more complex expression
```elixir
  [first_name, last_name] = ["Bill", "Evans"]
  q = from "artists", where: [name: ^(first_name <> " " <> last_name)], select: [:id, :name]
```

## Dynamic values and types
This works because the type is correct
```elixir
  artist_id = 1
  q = from "artists", where: [id: ^artist_id], select: [:id, :name]
  Repo.all(q)
```

Type must be cast to get this to work
```elixir
  artist_id = "1"
  q = from "artists", where: [id: type(^artist_id, :integer)], select: [:id, :name]
  Repo.all(q)
```

## Query Bindings
```elixir
  q = from a in "artists", where: a.id == 1, select: [:id, :name]
  Repo.all(q)
```

## Query Expressions
(full list)[https://hexdocs.pm/ecto/Ecto.Query.API.html]
```elixir
  q = from a in "artists", where: like(a.name, "Miles%"), select: [:id, :name]
  q = from a in "artists", where: is_nil(a.name), select: [:id, :name]
  q = from a in "artists", where: not is_nil(a.name), select: [:id, :name]
  q = from a in "artists", where: a.inserted_at < ago(1, "year"), select: [:id, :name]
  Repo.all(q)
```

## Fragments
used to insert raw sql into the query
```elixir
  q = from a in "artists", where: fragment("lower(?)", a.name) == "miles davis", select: [:id, :name]
  Repo.all(q)
```

## Extending Ecto Repo with `lower` fragment
```elixir
# in Repo
# defmacro lower(arg) do
#   quote do: fragment("lower(?)", unquote(arg))
# end
  q = from a in "artists", where: lower(a.name) == "miles davis", select: [:id, :name]
  Repo.all(q)
```

## Union
Union filters results to contain only unique rows, but that comes with db overhead
```elixir
  tracks_query = from t in "tracks", select: t.title
  union_query = from a in "albums", select: a.title, union: ^tracks_query
  Repo.all(union_query)
```


## Union All
Union all is more efficient, but only use it if you are certain there aren't duplicates or if you don't care
```elixir
  tracks_query = from t in "tracks", select: t.title
  union_query = from a in "albums", select: a.title, union_all: ^tracks_query
  Repo.all(union_query)
```

## Union Intersect
```elixir
  tracks_query = from t in "tracks", select: t.title
  intersect_query = from a in "albums", select: a.title, intersect: ^tracks_query
  Repo.all(union_query)
```

## Union Except
```elixir
  tracks_query = from t in "tracks", select: t.title
  except_query = from a in "albums", select: a.title, except: ^tracks_query
  Repo.all(except_query)
```


## Ordering
`order_by` is ascending by default
```elixir
  q = from a in "artists", select: [a.name], order_by: a.name
  q = from a in "artists", select: [a.name], order_by: [desc: a.name]
  q = from t in "tracks", select: [t.album_id, t.title, t.index], order_by: [t.album_id, t.index]
  q = from t in "tracks", select: [t.album_id, t.title, t.index], order_by: [desc: t.album_id, asc: t.index]
  q = from t in "tracks", select: [t.album_id, t.title, t.index], order_by: [desc_nulls_first: t.album_id, asc_nulls_last: t.index]
  Repo.all(q)
```

## Grouping
having is like a where clause that is applied after the totaling
```elixir
  q = from t in "tracks", select: [t.album_id, sum(t.duration)], group_by: t.album_id
  q = from t in "tracks", select: [t.album_id, sum(t.duration)], group_by: t.album_id, having: sum(t.duration) > 3600
  Repo.all(q)
```
