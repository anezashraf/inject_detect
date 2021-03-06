defmodule InjectDetect.RemoveExpectedQueryTest do
  use ExUnit.Case

  alias InjectDetect.Command.CreateUser
  alias InjectDetect.Command.IngestQueries
  alias InjectDetect.Command.RemoveExpectedQuery
  alias InjectDetect.Command.ToggleTrainingMode
  alias InjectDetect.State.Application
  alias InjectDetect.State.ExpectedQuery
  alias InjectDetect.State.User

  import InjectDetect.CommandHandler, only: [handle: 2]

  setup tags do
    InjectDetect.State.reset()

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(InjectDetect.Repo)
    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(InjectDetect.Repo, {:shared, self()})
    end
    :ok
  end

  test "removes an expected query" do
    %CreateUser{email: "email@example.com",
                application_name: "Foo Application",
                application_size: "Medium",
                agreed_to_tos: true}
    |> handle(%{})

    user = User.find(email: "email@example.com")
    application = Application.find(name: "Foo Application")

    %IngestQueries{application_id: application.id,
                   queries: [%{collection: "users",
                               type: "find",
                               queried_at: ~N[2017-03-28 01:30:00],
                               query: %{"_id" => "string"}}]}
    |> handle(%{})

    %ToggleTrainingMode{application_id: application.id}
    |> handle(%{user_id: user.id})

    query = ExpectedQuery.find(user.id, application.id, type: "find")

    %RemoveExpectedQuery{application_id: application.id,
                         query_id: query.id}
    |> handle(%{user_id: user.id})

    application = Application.find(name: "Foo Application")
    assert length(application.queries) == 0
  end

end
