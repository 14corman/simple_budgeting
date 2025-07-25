defmodule SimpleBudgetingWeb.Components.ExpandableSection do
  @moduledoc """
  Provides a section that will expand when clicked to show the
  hidden content.
  """

  use SimpleBudgetingWeb, :live_component

  def update(assigns, socket) do
    socket =
      if Map.has_key?(socket.assigns, :is_expanded) do
        assign(socket, assigns)
      else
        socket
        |> assign(assigns)
        |> assign(:is_expanded, assigns.expanded)
      end

    {:ok, socket}
  end

  def handle_event("toggle", _, socket) do
    {:noreply, assign(socket, :is_expanded, !socket.assigns.is_expanded)}
  end

  def render(assigns) do
    ~H"""
    <section id={@id} class="">
      <a
        class="select-none flex flex-row items-center py-1 cursor-pointer"
        phx-click={JS.push("toggle", target: @myself)}
      >
        <%= render_slot(@header, @is_expanded) %>
      </a>

      <%= if @is_expanded do %>
        <%= render_slot(@inner_block) %>
      <% end %>
    </section>
    """
  end
end
