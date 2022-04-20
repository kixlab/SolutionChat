# MicrongoPhx

To start your Phoenix server:

  * install elixir (https://elixir-lang.org/install.html)
  * install phoenix framework (https://hexdocs.pm/phoenix/installation.html)
  * install docker
  * run `sudo docker-compose up -d devel` for postgresql
  * run `cd nlu`
  * run `run.sh` for NLU
  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
