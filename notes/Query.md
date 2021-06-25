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

## Joins
Types of joins `inner` (default), `left_join`, `right_join`, `cross_join`, `full_join`
```elixir
  q = from t in "tracks",
    join: a in "albums", on: t.album_id == a.id,
    where: t.duration > 900, select: %{album: a.title, track: t.title}
  Repo.all(q)
```
### Prefix Joins
You can join across schemas with prefix
```elixir
  q = from t in "tracks", prefix: "public",
    join: a in "albums", prefix: "private", on: t.album_id == a.id,
    where: t.duration > 900, select: %{album: a.title, track: t.title}
  Repo.all(q)
```

### Multiple Joins
Elixir keyword lists allow the same keyword more than once. Use this for multiple joins
```elixir
  q = from t in "tracks",
    join: a in "albums", on: t.album_id == a.id,
    join: ar in "artists", on: a.artist_id == ar.id,
    where: t.duration > 900, select: %{album: a.title, track: t.title, artist: ar.name}
  Repo.all(q)

  # returning a kw list instead of a map
  q = from t in "tracks",
    join: a in "albums", on: t.album_id == a.id,
    join: ar in "artists", on: a.artist_id == ar.id,
    where: t.duration > 900, select: [album: a.title, track: t.title, artist: ar.name]
  Repo.all(q)
```

## Composing Queries
```elixir
  albums_by_miles = from a in "albums",
    join: ar in "artists", on: a.artist_id == ar.id,
    where: ar.name == "Miles Davis"
  album_query = from a in albums_by_miles, select: a.title
  Repo.all(album_query)
  track_query = from a in albums_by_miles,
    join: t in "tracks", on: a.id == t.album_id,
    select: t.title
  Repo.all(track_query)
```
When building queries the query bindings must be used in the same order in subsequent queries
```elixir
  albums_by_miles = from a in "albums",
    join: ar in "artists", on: a.artist_id == ar.id,
    where: ar.name == "Miles Davis"
  album_query = from [a,ar] in albums_by_miles, select: [a.title, ar.name]
  Repo.all(album_query)

  # WRONG. This will not work when sent to the Repo
  album_query = from [ar,a] in albums_by_miles, select: [a.title, ar.name]

  # You can change binding names
  album_query = from [album, artist] in albums_by_miles, select: [album.title, artist.name]
  Repo.all(album_query)

  # You can change binding names and omit what you don't need
  album_query = from album in albums_by_miles, select: album.title
  Repo.all(album_query)
```

To create named bindings use the `as` keyword
```elixir
  albums_by_miles = from a in "albums", as: :albums,
    join: ar in "artists", as: :artists, on: a.artist_id == ar.id,
    where: ar.name == "Miles Davis"
  # To use the named binding in another query add the name to the beginning of the from call
  album_query = from [albums: a, artists: ar] in albums_by_miles, select: [a.title, ar.name]
  # To check for a named binding
  has_named_binding?(albums_by_miles, :albums)
  has_named_binding?(album_query, :albums)
  Repo.all(album_query)
```

## Composing Queries With Functions
```elixir
  defmodule Q do
    import_if_available(Ecto.Query)

    def by_artist(query, artist_name) do
      from a in query,
        join: ar in "artists", on: a.artist_id == ar.id,
        where: ar.name == ^artist_name
    end

    def with_tracks_longer_than(query, duration) do
      from a in query,
        join: t in "tracks", on: t.album_id == a.id,
        where: t.duration > ^duration,
        distinct: true
    end

    def title_only(query) do
      from a in query, select: a.title
    end

    def exec do
      "albums"
        |> by_artist("Miles Davis")
        |> with_tracks_longer_than(720)
        |> title_only()
        |> Repo.all()
    end
  end
  Q.exec()
```

## Or Where
When composing queries sometimes you want `or` instead of `and` in your where clause
```elixir
  albums_by_miles = from a in "albums", as: :albums,
    join: ar in "artists", as: :artists, on: a.artist_id == ar.id,
    where: ar.name == "Miles Davis"
  q = from [a,ar] in albums_by_miles,
    or_where: ar.name == "Bobby Hutcherson",
    select: %{artist: ar.name, album: a.title}
  Repo.all(q)
```

## Queries can be used in othe `_all` functions
```elixir
  q = from t in "tracks", where: t.title == "Autum Leaves"
  Repo.update_all(q, set: [title: "Autumn Leaves"])
  Repo.delete_all(q, set: [title: "Autumn Leaves"])
```
