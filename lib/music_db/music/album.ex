# ---
# Excerpted from "Programming Ecto",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wmecto for more book information.
# ---
defmodule MusicDB.Music.Album do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias MusicDB.{Artist, Track, Genre}

  schema "albums" do
    field(:title, :string)
    timestamps()

    belongs_to(:artist, Artist)
    has_many(:tracks, Track)
    many_to_many(:genres, Genre, join_through: "albums_genres")
  end

  def changeset(album, params) do
    album
    |> cast(params, [:title])
    |> validate_required([:title])
  end

  def changeset2(album, params) do
    album
    |> cast(params, [:title])
    |> validate_required([:title])
    |> validate_length(:title, min: 100)
  end

  def search(string) do
    from(album in Album, where: ilike(album.title, ^"%#{string}%"))
  end
end
