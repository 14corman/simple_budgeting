defmodule SimpleBudgetingWeb.Router do
  use SimpleBudgetingWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SimpleBudgetingWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    # plug :fetch_current_user
  end

  # scope "/", SimpleBudgetingWeb do
  #   pipe_through [:browser, :redirect_if_user_is_authenticated]
  #   live "/login", Accounts.Login, as: :login

  #   post "/sessions/new", Accounts.SessionsController, :new
  # end

  # scope "/", SimpleBudgetingWeb do
  #   pipe_through [:browser, :check_user_and_pin]
  # end

  # live_session :default, on_mount: SimpleBudgetingWeb.Helpers.Authentication do
  #   scope "/", SimpleBudgetingWeb do
  #     pipe_through [:browser, :require_authenticated_user, :redirect_if_user_pin_ok]
  #     live "/change_pin", Accounts.ChangePin, as: :change_pin
  #   end

  #   scope "/", SimpleBudgetingWeb do
  #     pipe_through [:browser, :require_authenticated_user, :user_pin_uptodate]

  #     delete "/sessions/delete", Accounts.SessionsController, :delete

  #     # live "/", Index
  #   end
  # end

  scope "/", SimpleBudgetingWeb do
    pipe_through [:browser]

    live "/", Index

    scope "/transactions", Transactions do
      live "/", Index
      live "/show/:id", Show

      scope "/new", New do
        live "/", Transaction
        live "/compound_transaction", CompoundTransaction
        live "/paycheck", Paycheck
      end
    end

    scope "/accounts", Accounts do
      live "/", Index
      live "/:id", Show
    end

    scope "/receipt_sources", ReceiptSources do
      live "/", Index
      live "/:id", Show
    end

    scope "/budgets", Budgets do
      live "/", Index
      live "/balance_percent", Balance
      live "/:id", Show
    end

    scope "/locations", Locations do
      live "/", Index
      live "/:id", Show
    end

    scope "/ai_conversations", ConversationLive do
      live "/", Index, :index
      live "/new", Index, :new
      live "/:id/edit", Index, :edit

      live "/:id", Show, :show
      live "/:id/show/edit", Show, :edit
      live "/:id/edit_message/:msg_id", Show, :edit_message
    end

    live "/agent_chat/", AgentChatLive.Index, :index

    # live "/ai", Balance
    # live "/balance_accounts", Something
    # live "/tax_statements", Something
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Other scopes may use custom stacks.
  # scope "/api", SimpleBudgetingWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:simple_budgeting, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SimpleBudgetingWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
