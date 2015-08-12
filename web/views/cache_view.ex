defmodule News.CacheView do
  use News.Web, :view
  import Ecto.Model
  import Ecto.Query, only: [from: 2]

end
