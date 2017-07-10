defmodule InjectDetect.State do
  use GenServer

  import Ecto.Query

  @initial %{users: []}

  def start_link do
    GenServer.start_link(__MODULE__, {0, @initial}, name: __MODULE__)
  end

  def get do
    GenServer.call(__MODULE__, :get)
  end

  def all do
    GenServer.call(__MODULE__, :all)
  end

  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  defp convert_to_event(%{type: type, data: data}) do
    type = String.to_atom(type)
    data = InjectDetect.atomify(data)
    InjectDetect.Event.convert_from(struct(type, data), 0)
  end

  defp get_events_since(id) do
    events = InjectDetect.Model.Event
    |> where([event], event.id > ^id)
    |> order_by([event], event.id)
    |> InjectDetect.Repo.all
    |> Enum.to_list

    # Convert all events into their structs
    {events |> Enum.map(&convert_to_event/1),
    # Grab the most recent "id" we've seen
     events |> List.last |> (&(if &1 do &1.id else id end)).()}
  end

  def handle_call(:get, _, {id, state}) do
    {events, id} = get_events_since(id)
    state = Enum.reduce(events, state, &InjectDetect.State.Reducer.apply/2)
    {:reply, {:ok, state}, {id, state}}
  end

  def handle_call(:all, _, {id, state}) do
    {events, id} = get_events_since(id)
    state = Enum.reduce(events, state, &InjectDetect.State.Reducer.apply/2)
    {:reply, {:ok, id, state}, {id, state}}
  end

  def handle_call(:reset, _, _), do: {:reply, :ok, {0, @initial}}

end
