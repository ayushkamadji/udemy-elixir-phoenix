defmodule Discuss.TopicController do
    use Discuss.Web, :controller
    alias Discuss.Topic

    plug Discuss.Plugs.RequireAuth when action in [:new, :create, :edit, :update, :delete]
    plug :require_owner when action in [:edit, :update, :delete]

    def index(conn, _params) do
        topics = Repo.all(Topic)
        render conn, "index.html", topics: topics
    end

    def new(conn, _params) do
        changeset = Topic.changeset(%Topic{}, %{})
        render conn, "new.html", changeset: changeset
    end

    def create(conn, %{ "topic" => topic }) do
        changeset = conn.assigns.user
          |> build_assoc(:topics)
          |> Topic.changeset(topic)

        case Repo.insert(changeset) do
            {:ok, _topic} ->
                conn
                |> put_flash(:info, "Topic Created")
                |> redirect(to: topic_path(conn, :index))
            {:error, changeset} ->
                render conn, "new.html", changeset: changeset
        end
    end

    def edit(conn, %{ "id" => id }) do
        topic = Repo.get(Topic, id)
        changeset = Topic.changeset(topic)
        render conn, "edit.html", changeset: changeset, topic: topic
    end

    def update(conn, %{ "id" => id, "topic" => topic }) do
        old_topic = Repo.get(Topic, id)
        changeset = Topic.changeset(old_topic, topic)
        case Repo.update(changeset) do
            {:ok, _topic} ->
                conn
                |> put_flash(:info, "Topic updated")
                |> redirect(to: topic_path(conn, :index))
            {:error, changeset} ->
                render conn, "edit.html", changeset: changeset, topic: old_topic
        end
    end

    def delete(conn, %{ "id" => id }) do
        Repo.get!(Topic, id)
        |> Repo.delete!

        conn
        |> put_flash(:info, "Topic deleted")
        |> redirect(to: topic_path(conn, :index))
    end

    def require_owner(conn, _params) do
      %{params: %{"id" => topic_id}} = conn
      if Repo.get(Topic, topic_id).user_id == conn.assigns.user.id do
        conn
      else
        conn
        |> put_flash(:error, "You are not authorized to do that")
        |> redirect(to: topic_path(conn, :index))
        |> halt()
      end
    end
end