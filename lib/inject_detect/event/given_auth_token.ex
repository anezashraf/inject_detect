defmodule InjectDetect.Event.GivenAuthToken do
  defstruct auth_token: nil,
            user_id: nil

  def convert_from(event, _), do: struct(__MODULE__, event)

end

defimpl InjectDetect.State.Reducer,
  for: InjectDetect.Event.GivenAuthToken do

  def apply(event, state) do
    put_in(state, [:users,
                   InjectDetect.State.all_with(id: event.user_id),
                   :auth_token], event.auth_token)
  end

end
