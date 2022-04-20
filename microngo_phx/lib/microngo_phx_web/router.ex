defmodule MicrongoPhxWeb.Router do
  use MicrongoPhxWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    # plug :MicrongoPhxWeb.Locale
    # plug SetLocale, gettext: MicrongoPhxWeb.Gettext, default_locale: "en"
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", MicrongoPhxWeb do
    # Use the default browser stack
    pipe_through(:browser)
    # get("/", PageController, :index)
    # get("/login", LoginController, :index)
    # post("/login", LoginController, :post)
    # get("/ngo", NGOLookupController, :index)
    # get("/ngo/:id", NGOController, :index)
    get("/turk", TurkController, :index)
    get("/survey", SurveyController, :index)
    post "/survey", SurveyController, :create

    get("/", AgreeController, :index)
    get("/before", LandingController, :index)
    get("/after", AfterController, :index)

    get("/exp", ExpController, :index)
    post("/exp", ExpController, :create)

    get("/join", JoinController, :index)
    post("/join", JoinController, :create)
  end

  scope "/api", MicrongoPhxWeb do
    pipe_through(:api)
    post("/room/create", RoomApiController, :create)
    post("/user/create", UserApiController, :create)
    post("/user/token", UserApiController, :token)
  end
end
