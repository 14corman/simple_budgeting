defmodule SimpleBudgetingWeb.Components.MoneyInput do
  @moduledoc false
  use SimpleBudgetingWeb, :live_component

  # prop can_be_negative, :boolean, default: true
  # prop class, :css_class, default: ""
  # prop disabled, :boolean, default: false

  # data amount_string, :string, default: "$0.00"
  # data current_amount, :any, default: Money.new(0)
  # data field, :atom, from_context: {Surface.Components.Form.Field, :field}
  # data form, :struct, from_context: {Surface.Components.Form, :form}

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(amount_string: "$0.00")
      |> assign(current_amount: Money.new(0))

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    %{value: value, rest: rest} = assigns
    %{current_amount: current_amount} = socket.assigns
    current_amount = value || current_amount || Money.new(0)

    socket =
      socket
      |> assign(amount_string: Money.to_string(current_amount, symbol: false))
      |> assign(current_amount: current_amount)
      |> assign(disabled: Map.get(rest, :disabled, false))
      |> assign(assigns)

    {:ok, socket}
  end

  @impl true
  def handle_event("keyup", %{"key" => "-"}, socket) do
    %{current_amount: current_amount, id: id} = socket.assigns
    current_amount = Money.neg(current_amount)

    socket =
      socket
      |> assign(current_amount: current_amount)
      |> assign(amount_string: Money.to_string(current_amount, symbol: false))
      |> push_event("changed", %{id: id, value: Money.to_string(current_amount, symbol: false)})

    {:noreply, socket}
  end

  @impl true
  def handle_event("keydown", %{"key" => "Backspace"}, socket) do
    %{current_amount: current_amount, id: id} = socket.assigns
    amount = current_amount.amount

    current_amount =
      (amount / 10)
      |> trunc()
      |> Money.new()

    socket =
      socket
      |> assign(current_amount: current_amount)
      |> assign(amount_string: Money.to_string(current_amount, symbol: false))
      |> push_event("changed", %{id: id, value: Money.to_string(current_amount, symbol: false)})

    {:noreply, socket}
  end

  @impl true
  def handle_event("keyup", %{"key" => key}, socket) do
    %{current_amount: current_amount, id: id} = socket.assigns
    amount = current_amount.amount

    num_characters =
      current_amount
      |> Money.to_string(symbol: false, separator: "", delimiter: "")
      |> String.length()

    current_amount =
      if num_characters < 16 do
        case key do
          "0" -> amount * 10
          "1" -> amount * 10 + 1
          "2" -> amount * 10 + 2
          "3" -> amount * 10 + 3
          "4" -> amount * 10 + 4
          "5" -> amount * 10 + 5
          "6" -> amount * 10 + 6
          "7" -> amount * 10 + 7
          "8" -> amount * 10 + 8
          "9" -> amount * 10 + 9
          _ -> amount
        end
        |> Money.new()
      else
        current_amount
      end

    socket =
      socket
      |> assign(current_amount: current_amount)
      |> assign(amount_string: Money.to_string(current_amount, symbol: false))
      |> push_event("changed", %{id: id, value: Money.to_string(current_amount, symbol: false)})

    {:noreply, socket}
  end

  @impl true
  def handle_event("keydown", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("do_nothing", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} phx-hook="MoneyInput" class={[@class, "relative"]} phx-target={@myself}>
      <div class={[
        "bg-white relative w-full border border-gray-300 rounded-md text-left cursor-default focus:outline-none text-xs sm:text-sm flex flex-row",
        @disabled && "!bg-gray-200 !cursor-not-allowed"
      ]}>
        <input type="hidden" name={@name} id={"#{@id}_hidden_input"} value={@current_amount} />
        <span class="flex items-center border-r border-gray-300 px-2">
          <%= Money.Currency.get(@current_amount.currency).symbol %>
        </span>
        <input
          id={"#{@id}_text_input"}
          phx-keyup="keyup"
          phx-keydown="keydown"
          class="border-none !shadow-none focus:outline-none focus:ring-0 flex-grow text-xs sm:text-sm"
          phx-change="do_nothing"
          phx-target={@myself}
          type="tel"
          size="10"
          value={@amount_string}
          aria-required="true"
          aria-invalid="false"
          autocomplete="off"
          autocapitalize="off"
          autocorrect="off"
          disabled={@disabled}
        />
      </div>
    </div>
    """
  end
end
