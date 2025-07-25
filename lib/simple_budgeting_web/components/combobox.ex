defmodule SimpleBudgetingWeb.Components.Combobox do
  @moduledoc false
  use SimpleBudgetingWeb, :live_component

  defstruct selected_key: nil,
            open: false,
            options: []

  # prop options, :list, default: []

  # data value, :any, default: nil
  # data onfocus, :event, default: "onfocus"
  # data field, :atom, from_context: {Surface.Components.Form.Field, :field}
  # data form, :struct, from_context: {Surface.Components.Form, :form}

  # data combobox, :struct

  # slot default

  def mount(socket) do
    combobox = %__MODULE__{}

    socket =
      socket
      |> assign(combobox: combobox)
      |> assign(value: nil)

    {:ok, socket}
  end

  def update(assigns, socket) do
    %{options: options, form: form, field: field} = assigns
    %{combobox: combobox, value: value} = socket.assigns

    value = Phoenix.HTML.Form.input_value(form, field) || value || nil

    combobox = %{combobox | options: options}

    socket =
      socket
      |> assign(assigns)
      |> assign(combobox: combobox)
      |> assign(value: value)

    {:ok, socket}
  end

  def handle_event("focus", _, socket) do
    %{combobox: combobox} = socket.assigns
    combobox = %{combobox | open: true}
    {:noreply, assign(socket, combobox: combobox)}
  end

  def handle_event("blur", _, socket) do
    # %{combobox: combobox} = socket.assigns
    # combobox = %{combobox | open: false}
    # {:noreply, assign(socket, combobox: combobox)}
    {:noreply, socket}
  end

  # @impl true
  # def handle_event("blur", %{"key" => key}, socket) do
  #   %{combobox: combobox, id: id} = socket.assigns
  #   combobox = %{combobox | open: false}

  #   socket =
  #     socket
  #     |> assign(combobox: combobox)
  #     |> push_event("selected", %{id: id, value: key})

  #   {:noreply, socket}
  # end

  # @impl true
  # def handle_event("blur", _, socket) do
  #   {:noreply, socket}
  # end

  def handle_event("click-away", _, socket) do
    %{combobox: combobox} = socket.assigns
    combobox = %{combobox | open: false}
    {:noreply, assign(socket, combobox: combobox)}
  end

  def handle_event("select-click", %{"key" => key}, socket) do
    %{combobox: combobox, id: id} = socket.assigns
    combobox = %{combobox | open: false}

    socket =
      socket
      |> assign(combobox: combobox)
      |> assign(value: key)
      |> push_event("selected", %{id: id, value: key})

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook="Combobox"
      class="relative"
      phx-click-away="click-away"
      phx-blur="click-away"
      phx-target={@myself}
    >
      <.input field={{@form, @field}} type="hidden" value={@value} id={"#{@id}_hidden_input"} />
      <%= render_slot(@inner_block, %{combobox: @combobox, target: @myself}) %>
    </div>
    """
  end
end
