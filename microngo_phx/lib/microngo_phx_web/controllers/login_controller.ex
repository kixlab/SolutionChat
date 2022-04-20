defmodule MicrongoPhxWeb.JoinForm do
  defstruct email: "", password1: "", password2: ""

  defp check_email(error_map, form) do
    error_map
    |> Map.put(
      :email,
      [
        fn -> if form.email == "", do: "Email is blank", else: "" end
      ]
      |> Enum.map(fn testfn -> testfn.() end)
      |> Enum.filter(fn x -> x != "" end)
    )
  end

  defp check_password(error_map, form) do
    error_map
    |> Map.put(
      :password1,
      [
        fn -> if form.password1 == "", do: "Password cannot be blank", else: "" end,
        fn -> if form.password2 == "", do: "Password cannot be blank", else: "" end,
        fn -> if form.password1 != form.password2, do: "Password is not match", else: "" end
      ]
      |> Enum.map(fn testfn -> testfn.() end)
      |> Enum.filter(fn x -> x != "" end)
    )
  end

  def form_check(form) do
    # Data Sanitization
    doc = %{
      form: %{form | email: form.email |> String.trim()},
      errors: %{},
      valid: false
    }

    # Error checking
    doc = %{
      doc
      | errors:
          doc.errors
          |> check_email(doc.form)
          |> check_password(doc.form)
    }

    # Verdict
    doc = %{doc | valid: Enum.all?(doc.errors, fn {_, v} -> Enum.count(v) == 0 end)}

    doc
  end
end

defmodule MicrongoPhxWeb.LoginController do
  use MicrongoPhxWeb, :controller

  def index(conn, _assigns) do
    render(conn, "index.html", join_form: %MicrongoPhxWeb.JoinForm{}, errors: %{})
  end

  def post(conn, assigns) do
    join_form = %MicrongoPhxWeb.JoinForm{
      email: assigns["email"] || "",
      password1: assigns["password1"] || "",
      password2: assigns["password2"] || ""
    }

    doc = MicrongoPhxWeb.JoinForm.form_check(join_form)

    if doc.valid == true do
      {:ok, user} =
        User.Logic.signup(%{
          "email" => doc.form.email,
          "password" => doc.form.password1,
          "username" =>
            MicrongoPhxWeb.Helper.Name.generate_name() <> Integer.to_string(Enum.random(1..99))
        })

      IO.puts("cookie id")
      IO.puts(user.id)

      put_session(conn, :uid, user.id)
      |> redirect(to: "/ngo")
    else
      render(conn, "index.html", join_form: join_form, errors: doc.errors)
    end
  end
end
