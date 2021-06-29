defmodule MusicDB.Music do
  alias MusicDB.Music.{Album, Artist}
  alias MusicDB.Repo

  def get_artist(name) do
    Repo.get_by(Artist, name: name)
  end

  def all_albums_by_artist(artist) do
    Ecto.assoc(artist, :albums)
    |> Repo.all()
  end

  def search_albums(string) do
    string
    |> Album.search()
    |> Repo.all()
  end
end
