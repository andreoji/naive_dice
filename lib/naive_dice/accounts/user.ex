defmodule NaiveDice.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias NaiveDice.Accounts.User
  alias NaiveDice.Tickets.{Payment, Reservation}
  
  @moduledoc false

  schema "users" do
    field(:name, :string)
    field(:password, :string, virtual: true)
    field(:password_hash, :string)
    field(:username, :string)
    has_one :payment, Payment
    has_many :reservations, Reservation

    timestamps()
  end

  @doc false
  def create_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:name, :username, :password])
    |> validate_required([:name, :username, :password])
    |> validate_length(:username, min: 3, max: 10)
    |> validate_length(:password, min: 5, max: 10)
    |> unique_constraint(:username)
    |> put_password_hash()
  end

  defp put_password_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(pass))

      _ ->
        changeset
    end
  end
end