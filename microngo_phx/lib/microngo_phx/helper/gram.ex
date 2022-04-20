defmodule N do
  @spec gram(String.t, integer) :: list(String.t)
  def gram(payload, gram_target) do
    gram(
      String.graphemes(payload),
      [],
      [],
      gram_target
    )
  end

  def gram([adding|rest_list], buffer_list, gram_list, gram_target) do
    if Enum.count(buffer_list) < gram_target do
      buffer_list = buffer_list ++ [adding]
      if Enum.count(buffer_list) == gram_target do
        gram_list = gram_list ++ [Enum.join(buffer_list)]
        buffer_list = List.delete_at(buffer_list, 0)
        gram(rest_list, buffer_list, gram_list, gram_target)
      else
        gram(rest_list, buffer_list, gram_list, gram_target)
      end
    else
      gram_list = gram_list ++ [Enum.join(buffer_list)]
      buffer_list = List.delete_at(buffer_list, 0)
      gram(rest_list, buffer_list, gram_list, gram_target)
    end
  end

  def gram([], _buffer_list, gram_list, _gram_target) do
    gram_list
  end
end


