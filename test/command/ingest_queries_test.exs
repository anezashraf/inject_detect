defmodule InjectDetect.IngestQueriesTest do
  use ExUnit.Case

  alias InjectDetect.Command.GetStarted
  alias InjectDetect.Command.IngestQueries
  alias InjectDetect.Command.TurnOffTrainingMode
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


  test "ingests an unexpected query in training mode" do
    %GetStarted{email: "email@example.com",
                application_name: "Foo Application",
                application_size: "Medium",
                agreed_to_tos: true}
    |> handle(%{})

    application = Application.find(name: "Foo Application")

    %IngestQueries{application_id: application.id,
                   queries: [%{collection: "users",
                               type: "find",
                               queried_at: ~N[2017-03-28 01:30:00],
                               query: %{"_id" => "string"}},
                             %{collection: "users",
                               type: "find",
                               queried_at: ~N[2017-04-03 11:00:00],
                               query: %{"_id" => "string"}},
                             %{collection: "orders",
                               type: "remove",
                               queried_at: ~N[2017-04-03 12:00:00],
                               query: %{"_id" => %{"$gte" => "string"}}}
                            ]}
    |> handle(%{})

    application = Application.find(name: "Foo Application")
    assert Enum.member?(application.expected_queries, %{collection: "users",
                                                        type: "find",
                                                        query: %{"_id" => "string"}})
    assert Enum.member?(application.expected_queries, %{collection: "orders",
                                                        type: "remove",
                                                        query: %{"_id" => %{"$gte" => "string"}}})
  end

  test "ingests an unexpected query out of training mode" do
    %GetStarted{email: "email@example.com",
                application_name: "Foo Application",
                application_size: "Medium",
                agreed_to_tos: true}
    |> handle(%{})

    user = User.find(email: "email@example.com")
    application = Application.find(name: "Foo Application")

    %TurnOffTrainingMode{application_id: application.id}
    |> handle(%{user_id: user.id})

    %IngestQueries{application_id: application.id,
                   queries: [%{collection: "users",
                               type: "find",
                               queried_at: ~N[2017-03-28 01:30:00],
                               query: %{"_id" => "string"}},
                             %{collection: "users",
                               type: "find",
                               queried_at: ~N[2017-04-03 11:00:00],
                               query: %{"_id" => "string"}},
                             %{collection: "orders",
                               type: "remove",
                               queried_at: ~N[2017-04-03 12:00:00],
                               query: %{"_id" => %{"$gte" => "string"}}}
                            ]}
    |> handle(%{})

    application = Application.find(name: "Foo Application")
    assert Enum.member?(application.unexpected_queries, %{collection: "users",
                                                          type: "find",
                                                          query: %{"_id" => "string"}})
    assert Enum.member?(application.unexpected_queries, %{collection: "orders",
                                                          type: "remove",
                                                          query: %{"_id" => %{"$gte" => "string"}}})
  end

  test "ingests an expected and unexpected queries" do
    %GetStarted{email: "email@example.com",
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

    %TurnOffTrainingMode{application_id: application.id}
    |> handle(%{user_id: user.id})

    %IngestQueries{application_id: application.id,
                   queries: [%{collection: "users",
                               type: "find",
                               queried_at: ~N[2017-04-03 11:00:00],
                               query: %{"_id" => "string"}},
                             %{collection: "orders",
                               type: "remove",
                               queried_at: ~N[2017-04-03 12:00:00],
                               query: %{"_id" => %{"$gte" => "string"}}}]}
    |> handle(%{})

    application = Application.find(name: "Foo Application")
    assert Enum.member?(application.expected_queries, %{collection: "users",
                                                        type: "find",
                                                        query: %{"_id" => "string"}})
    assert Enum.member?(application.unexpected_queries, %{collection: "orders",
                                                          type: "remove",
                                                          query: %{"_id" => %{"$gte" => "string"}}})
  end

end
