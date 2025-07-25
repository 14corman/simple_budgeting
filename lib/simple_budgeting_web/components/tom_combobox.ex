defmodule SimpleBudgetingWeb.Components.TomCombobox do
  @moduledoc """
  An improved search selection component that is useful when having selections from large lists are necessary
  """
  use SimpleBudgetingWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="w-full" phx-hook="TomSearchSelect" id={@id} phx-update="ignore">
      <a
        phx-click={JS.push("tom_clear", target: @myself)}
        class="absolute text-sm link cursor-pointer right-0 top-0"
      >
        Clear selected
      </a>

      <select
        id={"#{@id}_select"}
        name={@name}
        class={[
          @class,
          "block w-full py-1.5 px-3 border border-gray-300 bg-white rounded-md shadow-sm focus:outline-none focus:ring-zinc-500 focus:border-zinc-500 sm:text-sm"
        ]}
        multiple={@multiple}
        {@rest}
      >
        <option value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
    </div>
    """
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> notify_tom_updates()

    {:ok, socket}
  end

  def handle_event("tom_clear", _, socket) do
    socket =
      push_event(socket, "tom_clear", %{
        id: socket.assigns.id
      })

    {:noreply, socket}
  end

  defp notify_tom_updates(%{assigns: assigns} = socket) do
    push_event(socket, "tom_update", %{
      id: assigns.id,
      value: assigns.value,
      options: assigns.options |> Enum.map(&encode_option/1)
    })
  end

  defp encode_option({name, value}) do
    %{
      text: name,
      value: value
    }
  end

  defp encode_option(option), do: option
end
