defmodule UI.SpriteLibrary do
  defstruct sprites: %{}

  def new(sprites \\ []) do
    Enum.reduce(sprites, %__MODULE__{}, fn {name, path}, sprite_library ->
      add(sprite_library, name, path)
    end)
  end

  def add(sprite_library, name, path) do
    priv_path =
      :crates
      |> :code.priv_dir
      |> Path.join(path)
    hash = Scenic.Cache.Support.Hash.file!(priv_path, :sha)
    %__MODULE__{
      sprite_library
      | sprites: Map.put(sprite_library.sprites, name, {priv_path, hash})
    }
  end

  def load_all(sprite_library) do
    Enum.each(sprite_library.sprites, fn {_name, {path, hash}} ->
      Scenic.Cache.Static.Texture.load(path, hash)
    end)
  end

  def image(sprite_library, name) do
    {_path, hash} = Map.fetch!(sprite_library.sprites, name)
    {:image, hash}
  end
end
