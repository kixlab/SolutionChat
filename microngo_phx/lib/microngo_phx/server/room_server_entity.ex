defmodule Room.Entity do
  def init_entity_check(state) do
    # Query From Entity For Chat ID
    # Make map and save to room_state
    %{state | entities: gen_entity_map(Entity.Query.all_by_room_id(state.id))}
  end

  def gen_entity_map(list), do: gen_entity_map(list, %{})
  def gen_entity_map([], map), do: map
  def gen_entity_map([h | t], map), do: gen_entity_map(t, Map.put(map, h.id, h))
end
