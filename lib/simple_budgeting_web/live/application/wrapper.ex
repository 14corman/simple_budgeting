defmodule SimpleBudgetingWeb.Application.Wrapper do
  @moduledoc false
  use SimpleBudgetingWeb, :html

  # attr :current_user, :any, default: nil
  attr :title, :string, required: true
  attr :context, :string, default: nil
  slot :inner_block, required: true

  def wrapper(assigns) do
    ~H"""
    <div>
      <%!-- <div id="activity_tracker" class="hidden" phx-hook="ActivityTracker">
        <%= button("",
          to: ~p"/sessions/delete",
          id: "session_timeout_logout_button",
          method: :delete
        ) %>
      </div> --%>

      <%!-- current_user={@current_user} --%>
      <.header title={@title} context={@context} />

      <main class="px-10">
        <%= render_slot(@inner_block) %>
      </main>
    </div>
    """
  end

  # attr :current_user, :any, required: true
  attr :title, :string, required: true
  attr :show_sidebar, :boolean, default: true
  attr :context, :string, default: "Transactions"

  defp header(assigns) do
    # git_sha =
    #   (System.get_env("GIT_REV") || "dev")
    #   |> String.slice(0..7)
    # version = Mix.Project.config()[:version]

    # assigns =
    #   assigns
    #   |> assign(git_sha: git_sha)
    #   |> assign(version: version)

    ~H"""
    <div>
      <div class="flex flex-row items-center px-10 mb-5 h-16 bg-gray-700">
        <a phx-click={show_sidebar()} class="cursor-pointer">
          <.icon name="hero-bars-3" class="h-6 w-6 text-emerald-200" />
        </a>
        <div class="flex flex-col items-start">
          <h1 class="ml-3 md:ml-10 text-emerald-200 font-semibold text-base md:text-lg">
            <%= @title %>
          </h1>
          <label class="ml-3 md:ml-10 text-xs md:text-sm text-white">
            <%= case @title do %>
              <% "Transactions" -> %>
                Adding and reviewing transactions
              <% "Accounts" -> %>
                Highest level money is stored (checking/savings accounts)
              <% "Budgets" -> %>
                Categories to link transactions to. These then link to accounts
              <% "Locations" -> %>
                Where transactions take place (think restaurants, gas stations, etc)
              <% "Receipt Sources" -> %>
                Ways that transactions can take place (think bank account, credit card, Apple pay, etc)
              <% "BalanceAccount" -> %>
                Balancing system accounts with what is expected
              <% "Tax" -> %>
                Building and printing tax forms from transactions
              <% "Conversations" -> %>
                Talk to the LLM behind SBAI
              <% "AI Agent" -> %>
                Ask SBAI questions about your finances
              <% _ -> %>
            <% end %>
          </label>
        </div>
        <div class="ml-auto flex flex-row items-center">
          <div class="text-base text-gray-700">
            <%!-- Hi, <%= @current_user.first_name %> <%= @current_user.last_name %> --%>
          </div>
          <%!-- button("Logout",
            to: Routes.sessions_path(@socket, :delete),
            method: :delete,
            class:
              "mt-auto py-2 text-white text-sm rounded-lg shadow ml-6 font-semibold bg-red-500 hover:bg-red-700 px-3"
          ) --%>
        </div>
      </div>

      <a
        id="app-sidebar-overlay"
        phx-click={hide_sidebar()}
        style="left: 0; top: 0; opacity:.55;"
        class="hidden fixed pin-t pin-l w-full h-full bg-black z-20"
      >
      </a>

      <div
        id="app-sidebar"
        style="top:0;left:0;"
        class="hidden bg-gray-700 fixed h-screen w-96 z-30 py-12 flex flex-col border"
      >
        <a phx-click={hide_sidebar()} class="block cursor-pointer border-b border-white pb-4">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="13"
            height="14"
            viewBox="0 0 13 14"
            class="w-6 h-6 fill-current text-white ml-12"
          >
            <path d="M12 7v1q0 .414-.254.707t-.66.293h-5.5l2.289 2.297q.297.281.297.703t-.297.703l-.586.594q-.289.289-.703.289-.406 0-.711-.289L.789 8.203Q.5 7.914.5 7.5q0-.406.289-.711l5.086-5.078q.297-.297.711-.297.406 0 .703.297l.586.578q.297.297.297.711t-.297.711L5.586 6h5.5q.406 0 .66.293T12 7z" />
          </svg>
        </a>

        <.sidebar_link label="Dashboard" path={~p"/"} active?={@context == "Dashboard"} />
        <.sidebar_link
          label="Transactions"
          path={~p"/transactions"}
          active?={@context == "Transactions"}
        />

        <.sidebar_link label="Accounts" path={~p"/accounts"} active?={@context == "Accounts"} />

        <.sidebar_link label="Budgets" path={~p"/budgets"} active?={@context == "Budgets"} />

        <.sidebar_link label="Locations" path={~p"/locations"} active?={@context == "Locations"} />

        <.sidebar_link
          label="Receipt Sources"
          path={~p"/receipt_sources"}
          active?={@context == "Receipt Sources"}
        />

        <.sidebar_link label="AI Conversations" path={~p"/ai_conversations"} active?={@context == "Conversations"} />

        <.sidebar_link label="SBAI" path={~p"/agent_chat"} active?={@context == "AI Agent"} />

        <.sidebar_link label="Balance Accounts" path={~p"/balance_accounts"} active?={@context == "BalanceAccounts"} />

        <.sidebar_link label="Tax Statements" path={~p"/tax_statements"} active?={@context == "Tax"} />

        <%!-- <div class="mt-auto flex flex-col justify-center items-center">
          <div class="my-3 text-xs text-center text-white">
            Simple Budgeting v.<%= @version %>.<%= @git_sha %>
          </div>

          <%= button("Logout",
            to: ~p"/sessions/delete",
            method: :delete,
            class:
              "py-3 text-white rounded-lg shadow w-64 font-semibold bg-red-500 hover:bg-red-700"
          ) %>
        </div> --%>
      </div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :active?, :boolean, required: true
  attr :path, :string, required: true

  defp sidebar_link(assigns) do
    ~H"""
    <.link
      class={[
        "w-full text-left border-b border-white pl-12 text-lg text-white font-semibold pr-10 py-4 hover:underline cursor-pointer",
        @active? && "bg-emerald-700"
      ]}
      navigate={@path}
    >
      <%= @label %>
    </.link>
    """
  end

  defp show_sidebar(js \\ %JS{}) do
    js
    |> JS.show(
      to: "#app-sidebar-overlay",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "#app-sidebar",
      display: "flex",
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 ", "opacity-100 translate-y-0"}
    )
  end

  defp hide_sidebar(js \\ %JS{}) do
    js
    |> JS.hide(
      to: "#app-sidebar",
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200", "opacity-100 translate-y-0",
         "opacity-0 translate-y-4 sm:translate-y-0 "}
    )
    |> JS.hide(
      to: "#app-sidebar-overlay",
      time: 200,
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
  end
end
