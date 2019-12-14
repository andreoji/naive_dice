defmodule NaiveDiceWeb.ReservationControllerTest do
  use NaiveDiceWeb.ConnCase
  import NaiveDiceWeb.Factory
  import Ecto.Query, warn: false
  alias NaiveDice.Tickets.Reservation
  alias NaiveDice.Repo

  describe "create/4" do
    setup [:create_event, :log_user_in]
    test "responds with a success message and creates a new reservation", %{
      conn: conn,
      params: params,
    } do
      conn = post(conn, Routes.reservation_path(conn, :create), params)

      assert redirected_to(conn) == Routes.payment_path(conn, :new)
      assert get_flash(conn, :info) == "Reservation successful"
    end

    test "responds with an error message when a reservation is created for a second time", %{
      conn: conn,
      params: params,
    } do
      conn = post(conn, Routes.reservation_path(conn, :create), params)
      conn = post(conn, Routes.reservation_path(conn, :create), params)

      assert redirected_to(conn) == Routes.payment_path(conn, :new)
      assert get_flash(conn, :error) == "You have a current reservation, proceed with payment"
    end

    test "responds with an error message when the full name is incorrect", %{
      conn: conn,
      params: params,
    } do
      conn = post(conn, Routes.reservation_path(conn, :create), %{params| "name" => "jane doe"})

      assert get_flash(conn, :error) == "The full name entered doesn't match"
    end
  end

  describe "create/4 when already reserved" do
    setup [:create_event, :log_user_in, :already_reserved]
    test "responds with a success message and creates a new reservation", %{
      conn: conn,
      params: params,
    } do
      conn = post(conn, Routes.reservation_path(conn, :create), params)

      assert redirected_to(conn) == Routes.payment_path(conn, :new)
      assert get_flash(conn, :error) == "You have a current reservation, proceed with payment"
    end
  end

  describe "create/4 when already reserved but expired" do
    setup [:create_event, :log_user_in, :create_an_expired_reservation]
    test "responds with a success message and resets the expired reservation to active", %{
      conn: conn,
      params: params,
      reservation: reservation
    } do
      conn = post(conn, Routes.reservation_path(conn, :create), params)

      assert redirected_to(conn) == Routes.payment_path(conn, :new)
      assert get_flash(conn, :info) == "Reservation successful"
      reservation = reservation |> reload_reservation

      assert reservation.status == :active
    end
  end

  describe "create/4 when user has an existing expired reservation on login" do
    setup [:create_event, :create_user_with_expired_reservation, :log_user_in]
    test "responds with a success message and resets the expired reservation to active", %{
      conn: conn,
      params: params,
      reservation: reservation
    } do
      conn = post(conn, Routes.reservation_path(conn, :create), params)

      assert redirected_to(conn) == Routes.payment_path(conn, :new)
      assert get_flash(conn, :info) == "Reservation successful"
      reservation = reservation |> reload_reservation

      assert reservation.status == :active
    end
  end

  describe "create/4 when event is sold out" do
    setup [:create_sold_out_event, :log_user_in]
    test "responds with an error message the event is sold out", %{
      conn: conn,
      params: params,
    } do
      conn = post(conn, Routes.reservation_path(conn, :create), params)

      assert get_flash(conn, :error) == "Sorry The Sound of Music is now sold out"
    end
  end

  defp log_user_in(context), do: do_log_user_in(context)

  defp do_log_user_in(%{event: _event, user: user} = context) do
    conn = build_conn()
    conn = post(conn, Routes.session_path(conn, :create), session: %{username: user.username, password: user.password})
    context |> Map.merge(%{conn: conn, params: %{"name" => user.name}})
  end

  defp do_log_user_in(%{event: _event} = context) do
    user = insert(:user)
    conn = build_conn()
    conn = post(conn, Routes.session_path(conn, :create), session: %{username: user.username, password: user.password})
    context |> Map.merge(%{conn: conn, params: %{"name" => user.name}, user: user})
  end

  defp create_event(context) do
    event = insert(:event)
    context |> Map.merge(%{event: event})
  end

  defp create_sold_out_event(context) do
    event = insert(:event, event_status: :sold_out, number_sold: 5)
    context |> Map.merge(%{event: event})
  end
  defp already_reserved(%{event: event, user: user} = context) do
    insert(:reservation, event_id: event.id, user_id: user.id)
    context
  end

  defp create_user_with_expired_reservation(%{event: event} = context) do
    user = insert(:user)
    reservation = insert(:reservation, event_id: event.id, user_id: user.id, status: :expired)
    context |> Map.merge(%{user: user, reservation: reservation})
  end

  defp create_an_expired_reservation(%{event: event, user: user} = context) do
    reservation = insert(:reservation, event_id: event.id, user_id: user.id, status: :expired)
    context |> Map.merge(%{reservation: reservation})
  end

  defp reload_reservation(reservation) do
    Repo.get(Reservation, reservation.id)
  end
end