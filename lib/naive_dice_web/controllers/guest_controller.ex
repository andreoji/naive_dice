defmodule NaiveDiceWeb.GuestController do
  use NaiveDiceWeb, :controller
  require Logger
  alias NaiveDice.Tickets
  alias NaiveDice.Teardown
  import NaiveDice.Auth, only: [load_current_user: 2]
  import NaiveDice.Tickets, only: [load_event: 2]
  plug(:load_current_user)
  plug(:load_event)


  def action(conn, _) do
    apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user, conn.assigns.event])
  end

  def index(conn, _params, _user, event) do
  	guests = event |> Tickets.guests
    render(conn, "index.html", guests: guests)
  end

  def create(conn, _params, _user, event) do
    event
      |> Teardown.rip_it_up_and_start_again
      |> case do
        :successful_teardown ->
          :successful_teardown
        {:unsuccessful_teardown, _error} = e ->
          Logger.error(inspect e)

    end
    render(conn, "index.html", guests: [])
  end
end