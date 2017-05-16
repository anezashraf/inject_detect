defmodule InjectDetect.Event.RemovedApplication do
  defstruct id: nil,
            user_id: nil

  def convert_from(event, _), do: struct(__MODULE__, event)

end

defimpl InjectDetect.State.Reducer,
   for: InjectDetect.Event.RemovedApplication do

  alias InjectDetect.State.User

  def apply(event, state) do
    User.remove_application(state, event.user_id, event.id)
  end

end
