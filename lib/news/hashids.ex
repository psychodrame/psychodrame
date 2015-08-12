defmodule News.Hashids do
  @supported_modules [News.Story, News.Comment]

  def encode(model=%{__struct__: module}) when module in @supported_modules do
    apply(module, :encode_id, [model])
  end

  def decode(model=%{__struct__: module}) when module in @supported_modules do
    apply(module, :decode_id, [model])
  end

  def get_from_hashid(model=%{__struct__: module}) when module in @supported_modules do
    apply(module, :get_from_hashid, [model])
  end

end
