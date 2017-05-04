defmodule InjectDetect.Event.MarkedQueryAsExpected do
  defstruct application_id: nil,
            query_id: nil

  def convert_from(event, _), do: struct(__MODULE__, event)

end

defimpl InjectDetect.State.Reducer,
   for: InjectDetect.Event.MarkedQueryAsExpected do

  alias InjectDetect.State.Application
  alias InjectDetect.State.UnexpectedQuery

  def apply(event, state) do
    query = UnexpectedQuery.find(state, event.query_id)
    state
    |> UnexpectedQuery.remove(event.query_id)
    |> Application.add_expected_query(event.application_id, query)
  end

end