defmodule News.Util.DeadSHA do

  @dead %{
    "f0e377c20a27c8d9bb6ec16bdfb5d2e21b38c9e6" => "bitpixels: thumbnail coming soon",
    "20002faf28adfd94ca98cf6ced46f14334b53684" => "imgur: removed",
    "c5062ff0872b6bed499dfbdbbc018905f4ba3f51" => "tumblr: removed",
    "89d01ca36235bc1a64b99cf8350ca3818da71ba7" => "tumblr: removed because copyright",
  }

  @dead_shas Map.keys(@dead)

  def dead?(sha), do: sha in @dead
end
