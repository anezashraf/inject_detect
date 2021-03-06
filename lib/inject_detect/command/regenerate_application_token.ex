defmodule InjectDetect.Command.RegenerateApplicationToken do
  defstruct application_id: nil
end

defimpl InjectDetect.Command,
   for: InjectDetect.Command.RegenerateApplicationToken do

  alias InjectDetect.Event.RegeneratedApplicationToken
  alias InjectDetect.State.Application

  def regenerate_application_token(application = %{user_id: user_id}, _command, %{user_id: user_id}) do
    application_token = InjectDetect.generate_token(application.id)
    {:ok, [%RegeneratedApplicationToken{application_id: application.id,
                                        token: application_token,
                                        user_id: user_id}], %{application_id: application.id}}
  end

  def regenerate_application_token(_application, _command, _context) do
    {:error, %{code: :not_authorized,
               error: "Not authorized",
               message: "Not authorized"}}
  end

  def handle(command, context, state) do
    Application.find(state, command.application_id)
    |> regenerate_application_token(command, context)
  end

end
