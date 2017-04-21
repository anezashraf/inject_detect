defmodule InjectDetect.RegenerateApplicationTokenTest do
  use ExUnit.Case

  alias InjectDetect.Command.GetStarted
  alias InjectDetect.Command.RegenerateApplicationToken
  alias InjectDetect.State
  alias InjectDetect.State.User
  alias InjectDetect.State.Application

  import InjectDetect.CommandHandler, only: [handle: 2]

  setup tags do
    InjectDetect.State.reset()

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(InjectDetect.Repo)
    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(InjectDetect.Repo, {:shared, self()})
    end
    :ok
  end

  test "toggles training mode" do
    %GetStarted{email: "email@example.com",
                application_name: "Foo Application",
                application_size: "Medium",
                agreed_to_tos: true}
    |> handle(%{})

    user = User.find(email: "email@example.com")
    application = Application.find(name: "Foo Application")
    token = application.token

    assert State.get()
    |> elem(1)
    |> get_in([:application_tokens, token]) == application.id

    %RegenerateApplicationToken{application_id: application.id}
    |> handle(%{user_id: user.id})

    application = Application.find(name: "Foo Application")
    assert application.token != token

    assert State.get()
    |> elem(1)
    |> get_in([:application_tokens, application.token]) == application.id

    assert State.get()
    |> elem(1)
    |> get_in([:application_tokens, token]) == nil
  end

end