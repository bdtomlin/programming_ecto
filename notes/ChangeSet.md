# ChangeSet

## Empty Values
By default `cast` will treat an empty string as nil
Add `empty_values` option to modify this to let blank strings in or add additional empty values

```elixir
params = %{"name" => "Bryan Tomlin", nick_name: ""}
changeset = cast(%Artist{}, params, [:name, :nick_name] )
changeset.changes
# => %{name: "Bryan Tomlin", nick_name: nil}

params = %{"name" => "Bryan Tomlin", nick_name: ""}
changeset = cast(%Artist{}, params, [:name, :nick_name], empty_values: [] )
changeset.changes
# => %{name: "Bryan Tomlin", nick_name: ""}

params = %{"name" => "Bryan Tomlin", nick_name: "NULL"}
changeset = cast(%Artist{}, params, [:name, :nick_name], empty_values: ["", "NULL"] )
changeset.changes
# => %{name: "Bryan Tomlin", nick_name: nil}
```


## Validations
```elixir
# valid
# params = %{"name" => "Thelonius Monk", "birth_date" => "1917-10-10"}
# invalid
params = %{"name" => "Thelonius Monk"}
changeset =
  %Artist{} \
  |> cast(params, [:name, :birth_date]) \
  |> validate_required([:name, :birth_date]) \
  |> validate_length(:name, min: 3)
```

```elixir
changeset =
  %Artist{} \
  |> cast(%{}, [:name, :birth_date]) \
  |> validate_required([:name, :birth_date]) \
  |> validate_length(:name, min: 3)
```

`Use Ecto.Changeset.traverse_errors` to make errors easier to deal with in code
```elixir
params = %{name: "Br"}
changeset =
  %Artist{} \
  |> cast(params, [:name, :birth_date]) \
  |> validate_required([:name, :birth_date]) \
  |> validate_length(:name, min: 3) \
  |> validate_length(:name, max: 1)

traverse_errors(changeset, fn {msg, opts} ->
  Enum.reduce(opts, msg, fn {k, v}, acc ->
    String.replace(acc, "%{#{k}}", to_string(v))
  end)
end)
```

### Custom Validation with `validate_change` (inline)
```elixir
params = %{"name" => "Thelonius Monk", "birth_date" => "2117-10-10"}
changeset =
  %Artist{} \
  |> cast(params, [:name, :birth_date]) \
  |> validate_change(:birth_date, fn :birth_date, birth_date ->
    cond do
      is_nil(birth_date) -> []
      Date.compare(birth_date, Date.utc_today()) == :lt -> []
      true -> [birth_date: "must be in the past"]
    end
  end)
  changeset.errors
```

### Custom Validation with a separate function
```elixir
defmodule V do
  def validate_birth_date_in_the_past(changeset, field) do
    validate_change(changeset, field, fn _field, value ->
      cond do
        is_nil(value) -> []
        Date.compare(value, Date.utc_today()) == :lt -> []
        true -> [{field, "must be in the past"}]
      end
    end)
  end
end
params = %{"name" => "Thelonius Monk", "birth_date" => "2117-10-10"}
changeset =
  %Artist{} \
  |> cast(params, [:name, :birth_date]) \
  |> V.validate_birth_date_in_the_past(:birth_date)
  changeset.errors
```

## Constraints (database validation)
Without constraint function
```elixir
Repo.insert(%Genre{name: "speed polka"})
Repo.insert(%Genre{name: "speed polka"})
# => gives an error due to database constraint
```

With constraint function
```elixir
params = %{"name" => "bebop"}
Repo.insert!(params)

changeset =
  %Genre{} \
  |> cast(params, [:name]) \
  |> validate_required(:name) \
  |> validate_length(:name, min: 3) \
  |> unique_constraint(:name)
changeset.errors
# => []

case Repo.insert(changeset) do
  {:ok, _genre} -> IO.puts("success")
  {:error, changeset} -> IO.inspect(changeset.errors)
end
# => [name: {"has already been taken", [constraint: :unique, constraint_name: "genres_name_index"]}]
```

Constraints act as circuit breakers. If one fails, none of the others are run. Also, if a regular validation fails
none of the constraints will run.

To avoid the issue of having one thing validate at a time while the user continually submits the form,
you can use `unsafe_validate_unique` along with `unique_constraint` which can provide a better user
experience in normal circumstances while still catching the rare race condition.

```elixir
params = %{"name" => "bebop"}
changeset =
  %Genre{} \
  |> cast(params, [:name]) \
  |> validate_required(:name) \
  |> validate_length(:name, min: 3) \
  |> unsafe_validate_unique(:name, Repo) \
  |> unique_constraint(:name)
changeset.errors
# => [ name: {"has already been taken", [validation: :unsafe_unique, fields: [:name]]} ]
```

## Changesets without schemas
```elixir
form = %{artist_name: :string, album_title: :string, artist_birth_date: :date, album_release_date: :date, genre: :string}

params = %{"artist_name" => "Ella Fitzgerald", "album_title" => "", "artist_birth_date" => "", "album_release_date" => "", "genre" => ""}

changeset =
  {%{}, form} \
  |> cast(params, Map.keys(form)) \
  |> validate_required(:album_title)

if changeset.valid? do
  # execute the advanced search
else
  # show changeset errors to the user
end
```

## Associations
```elixir
artist = Repo.get_by(Artist, name: "Miles Davis")
new_album = Ecto.build_assoc(artist, :albums)
```

```elixir
artist = Repo.get_by(Artist, name: "Miles Davis")
new_album = Ecto.build_assoc(artist, :albums, title: "Miles Ahead")
Repo.insert(new_album)
```

The following will raise an error. The `put_assoc` association has to have one of the following options
set in the schema for `on_replace:`:
`raise`(default), `mark_as_invalid`, `nilify`, `update`, `delete`
```elixir
changeset =
  Repo.get_by(Artist, name: "Miles Davis") \
  |> Repo.preload(:albums) \
  |> change \
  |> put_assoc(:albums, [%Album{title: "Miles Ahead"}]) \
  |> Repo.update
```

One way to make it work is as follows:
```elixir
artist =
  Repo.get_by(Artist, name: "Miles Davis") \
  |> Repo.preload(:albums)

artist \
  |> change \
  |> put_assoc(:albums, [%Album{title: "Miles Ahead"} | artist.albums]) \
  |> Repo.update
```

`put_assoc` works as expected when inserting a new record with associations
`put_assoc` also works with maps and keyword lists, not just schemas.


### Association validations with `cast_assoc`
This expects the association to have a changeset function called changeset by default.
```elixir
params = %{"name" => "Esperanza, Spalding", "albums" => [%{"title" => "Junjo"}]}

changeset =
  %Artist{} \
  |> cast(params, [:name]) \
  |> cast_assoc(:albums)
changeset.changes
```

You can specify the changeset as follows
```elixir
params = %{"name" => "Esperanza, Spalding", "albums" => [%{"title" => "Junjo"}]}

changeset =
  %Artist{} \
  |> cast(params, [:name]) \
  |> cast_assoc(:albums, with: &MusicDB.Album.changeset2/2)
changeset.changes
```

You can specify the changeset as follows
```elixir
params = %{"name" => "Esperanza, Spalding", "albums" => [%{"title" => "Junjo"}]}

changeset =
  %Artist{} \
  |> cast(params, [:name]) \
  |> cast_assoc(:albums, with: &MusicDB.Album.changeset2/2)
changeset.changes
```

#### `cast_assoc` details
* If the id already exists in the database and it's association to the current relation, it will get updated
* If the id already exists in the database and it's not association to the current relation, a new on gets created and the previous one remains untouched
* If the id in not in the update changeset, the `on_replace` options will be used which defaults to raising an error.
* If the id in not in the update changeset, the `on_replace` options will be used which defaults to raising an error.


#### Associations Best Practices
* Ask yourself if you want to work with the individual child records or the collection as a whole
* If you're working with the individual records, eg. inserting or deleting a single child, it's usually easiest to work with the child record separate from the parent.
* If working with the collection, think about what to do with records that are removed or replaced on update. Then, add the `on_replace` option to the schema association.
* If data is from an external source, use `cast_assoc`
* If data is internal, use `put_assoc`
* Don't forget on internally generated data you can bypass changesets and use `Repo.insert`.
* put_assoc is also a good choice when you’re managing parent and child records separately, even when working with external data. You could, for example, use changesets to create/update/delete the child records on their own, then use put_assoc in a separate changeset to update the collection on the parent record. This is often a great way to work with many-to-many associations.
