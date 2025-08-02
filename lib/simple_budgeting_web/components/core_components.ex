defmodule SimpleBudgetingWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as modals, tables, and
  forms. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component
  use Gettext, backend: SimpleBudgetingWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true
  slot :title
  slot :subtitle
  slot :footer

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      data-show-modal={show_modal(@id)}
      data-hide-modal={hide_modal(@id)}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5 w-full pl-12 flex flex-row justify-between">
                <header :if={@title != []}>
                  <h1 id={"#{@id}-title"} class="text-lg font-semibold leading-8 text-zinc-800">
                    <%= render_slot(@title) %>
                  </h1>
                  <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
                    <%= render_slot(@subtitle) %>
                  </p>
                </header>
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                {render_slot(@inner_block)}
              </div>
              <div :if={@footer != []} class="ml-6 mt-5 flex items-row justify-end space-x-3">
              <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  aria-label={gettext("close")}
                  class="simple_budgeting button white"
                >
                  Cancel
                </button>
                <%= render_slot(@footer) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        {@title}
      </p>
      <p class="mt-2 text-sm leading-5">{msg}</p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title={gettext("Success!")} flash={@flash} />
      <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        {gettext("Hang in there while we get back on track")}
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the data structure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-white">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               range search select tel text textarea time url week hidden code radio
               search_select checkboxes radios money debit_credit_radios)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :class, :string, default: nil
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step data-tom-createable data-tom-sortable)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "search_select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="field w-full relative">
      <.label for={"#{@id}_select"} :if={@label}><%= @label %></.label>
      <div class="w-5 h-5" :if={!@label}></div>
      <.live_component
        id={@id || @name}
        module={SimpleBudgetingWeb.Components.TomCombobox}
        name={@name}
        class={@class}
        multiple={@multiple}
        options={@options}
        value={@value}
        rest={@rest}
        prompt={@prompt}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "checkboxes"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="field">
      <.label for={@id}><%= @label %></.label>
      <fieldset class="grid grid-cols-4 gap-2 mt-2 mb-2">
        <%= for {item, value} <- @options do %>
          <label class="flex flex-row items-center space-x-2 ">
            <input
              type="checkbox"
              class="rounded border-zinc-300 text-primary-500 focus:ring-primary-500"
              name={@name}
              value={Phoenix.HTML.Form.normalize_value("checkbox", value)}
              checked={Enum.member?(assigns.value || [], value)}
            />
            <span class="text-gray-500 text-base"><%= item %></span>
          </label>
        <% end %>
      </fieldset>

      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "code"} = assigns) do
    ~H"""
    <div id={"#{@id}_ace"} phx-hook="AceEditor" phx-update="ignore" phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <input
        type="hidden"
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        {@rest}
      />
      <div id={"#{@id}_ace_wrapper"} class="text-base font-mono" data-editor-container></div>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  # def input(%{type: "radios"} = assigns) do
  #   assigns = assign_new(assigns, :options, fn -> [{"Yes", true}, {"No", false}] end)

  #   ~H"""
  #   <div phx-feedback-for={@name} class="field">
  #     <.label for={@id}><%= @label %></.label>
  #     <fieldset class="grid grid-cols-2 gap-2 mt-2 mb-2">
  #       <%= for {k,v} <- @options do %>
  #         <.input
  #           type="radio"
  #           class="rounded border-zinc-300 text-primary-500 focus:ring-primary-500"
  #           id={"#{@id}_#{k}"}
  #           value={v |> to_string()}
  #           checked={to_string(@value) == to_string(v)}
  #           label={k}
  #         />
  #       <% end %>
  #     </fieldset>

  #     <.error :for={msg <- @errors}><%= msg %></.error>
  #   </div>
  #   """
  # end

  # def input(%{type: "debit_credit_radios"} = assigns) do
  #   ~H"""
  #   <div phx-feedback-for={@name} class="field">
  #     <.label for={@id}><%= @label %></.label>
  #     <fieldset class="flex flex-row space-x-7 mt-2 mb-2">
  #       <label class="flex flex-row items-center space-x-2">
  #         <input
  #           type="radio"
  #           class="text-emerald-600 focus:ring-emerald-500 focus:ring-2"
  #           name={@name}
  #           value={"Debit" |> to_string()}
  #           checked={(to_string(@value) == "Debit") |> to_string()}
  #           {@rest}
  #         />
  #         <span class="font-bold ml-1 !text-red-700">Debit (-)</span>
  #       </label>

  #       <label class="flex flex-row items-center space-x-2 ">
  #         <input
  #           type="radio"
  #           class="text-emerald-600 focus:ring-emerald-500 focus:ring-2"
  #           name={@name}
  #           value={"Credit"}
  #           checked={(to_string(@value) == "Credit") |> to_string()}
  #           {@rest}
  #         />
  #         <span class="font-bold ml-1 !text-green-700">Credit (+)</span>
  #       </label>
  #     </fieldset>

  #     <.error :for={msg <- @errors}><%= msg %></.error>
  #   </div>
  #   """
  # end

  def input(%{type: "radio"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <input
        type="radio"
        id={@id}
        name={@name}
        value={@value}
        checked={@checked}
        class={@class || "rounded border-zinc-300 text-zinc-900 focus:ring-0"}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div>
      <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
          {@rest}
        />
        {@label}
      </label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <select
        id={@id}
        name={@name}
        class="mt-2 block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-zinc-400 focus:ring-0 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 min-h-[6rem]",
          input_border(@errors)
        ]}
        {@rest}
      >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type={@type} name={@name} id={@id || @name} value={@value} {@rest} />
    """
  end

  def input(%{type: "search"} = assigns) do
    assigns = assign_new(assigns, :placeholder, fn -> "Search..." end)

    ~H"""
    <div class="relative w-full max-w-xl">
      <div phx-feedback-for={@name} class="field relative w-full max-w-xl">
        <%= if @label do %>
          <.label for={@id}><%= @label %></.label>
        <% end %>
        <input
          type={@type}
          name={@name}
          id={@id || @name}
          value={@value}
          class={[
            input_border(@errors),
            @class,
            "text-black md:py-4 pl-7 md:pl-12 md:pr-4 md:mb-3 focus:ring-emerald-500 focus:border-emerald-500 leading-tight text-xs md:text-base bg-white relative w-full border border-gray-300 rounded-md shadow-sm  text-left focus:outline-none  ring-transparent flex flex-row"
          ]}
          {@rest}
        />

        <.icon name="hero-magnifying-glass" class="absolute top-0 mt-2 md:mt-5 ml-2 md:ml-5 md:w-4 md:h-4" />
        <.error :for={msg <- @errors}><%= msg %></.error>
      </div>
      <div class="while-submitting">
        <.icon name="hero-arrow-path" class="animate-spin" />
        <%!-- Spinner SVG (Not found in heroiocon) --%>
        <%!-- <svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><style>.spinner_P7sC{transform-origin:center;animation:spinner_svv2 .75s infinite linear}@keyframes spinner_svv2{100%{transform:rotate(360deg)}}</style><path d="M10.14,1.16a11,11,0,0,0-9,8.92A1.59,1.59,0,0,0,2.46,12,1.52,1.52,0,0,0,4.11,10.7a8,8,0,0,1,6.66-6.61A1.42,1.42,0,0,0,12,2.69h0A1.57,1.57,0,0,0,10.14,1.16Z" class="spinner_P7sC"/></svg> --%>
      </div>
    </div>
    """
  end

  def input(%{type: "money"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="field relative w-full max-w-xl">
      <%= if @label do %>
        <.label for={@id}><%= @label %></.label>
      <% end %>
      <.live_component
        id={@id}
        module={SimpleBudgetingWeb.Components.MoneyInput}
        name={@name}
        class={@class}
        multiple={@multiple}
        field={@field}
        value={@value}
        rest={@rest}
      />

      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div>
      <.label for={@id}>{@label}</.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6",
          input_border(@errors)
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders a fieldset with multiple radio buttons representing `Ecto.Enum` fields.
  note: string interpolation of `@field.value` is because it can switch from an atom to string
        depending on whether it came from the database or form

  # Example
    <.radio_fieldset field={@form[:visibility]}
      options={Ecto.Enum.dump_values(Scheduling.Calendar, :visibility)}
      checked_value={@form.params["visibility"]}
    />
  """
  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"
  attr :options, :list, doc: "the options for the radio buttons in the fieldset"
  attr :checked_value, :string, doc: "the currently checked value"

  def radio_fieldset(%{field: %Phoenix.HTML.FormField{}} = assigns) do
    assigns = assign_new(assigns, :options, fn -> [{"Yes", true}, {"No", false}] end)

    ~H"""
    <div phx-feedback-for={@field.name}>
      <fieldset class="grid grid-cols-2 gap-2 my-2">
        <.input :for={{k,v} <- @options}
          field={@field}
          id={"#{@field.id}_#{k}"}
          type="radio"
          class="rounded border-zinc-300 text-primary-500 focus:ring-primary-500"
          value={v |> to_string()}
          label={k}
          checked={(@checked_value == v) || (@field.value == v)}
        />
        </fieldset>
    </div>
    """
  end

  @doc """
  Renders a fieldset with multiple radio buttons representing `Ecto.Enum` fields.
  note: string interpolation of `@field.value` is because it can switch from an atom to string
        depending on whether it came from the database or form

  # Example
    <.debit_credit_radio_fieldset field={@form[:visibility]}
      checked_value={@form.params["visibility"]}
    />
  """
  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"
  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step data-tom-createable data-tom-sortable)

  def debit_credit_radio_fieldset(%{field: %Phoenix.HTML.FormField{}} = assigns) do
    ~H"""
    <div phx-feedback-for={@field.name}>
      <.label>Type*</.label>
      <fieldset class="grid grid-cols-2 gap-2 my-2">
        <div class="flex flex-row space-x-2">
          <.input
            field={@field}
            id={"#{@field.id}_debit"}
            type="radio"
            class="text-emerald-600 focus:ring-emerald-500 focus:ring-2"
            value={"Debit"}
            checked={@field.value == "Debit"}
            {@rest}
          />
          <span class="font-bold ml-1 !text-red-700">Debit (-)</span>
        </div>
        <div class="flex flex-row space-x-2">
          <.input
            field={@field}
            id={"#{@field.id}_credit"}
            type="radio"
            class="text-emerald-600 focus:ring-emerald-500 focus:ring-2"
            value={"Credit"}
            checked={@field.value == "Credit"}
            {@rest}
          />
          <span class="font-bold ml-1 !text-green-700">Credit (+)</span>
        </div>
        </fieldset>
    </div>
    """
  end

  defp input_border([] = _errors),
    do: "border-zinc-300 focus:border-zinc-400"

  defp input_border([_ | _] = _errors),
    do: "border-rose-400 focus:border-rose-400"

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-semibold leading-6 text-zinc-800">
      {render_slot(@inner_block)}
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-rose-600">
      <.icon name="hero-exclamation-circle-mini" class="mt-0.5 h-5 w-5 flex-none" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  # @doc """
  # Renders a header with title.
  # """
  # attr :class, :string, default: nil

  # slot :inner_block, required: true
  # slot :subtitle
  # slot :actions

  # def header(assigns) do
  #   ~H"""
  #   <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
  #     <div>
  #       <h1 class="text-lg font-semibold leading-8 text-zinc-800">
  #         {render_slot(@inner_block)}
  #       </h1>
  #       <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-zinc-600">
  #         {render_slot(@subtitle)}
  #       </p>
  #     </div>
  #     <div class="flex-none">{render_slot(@actions)}</div>
  #   </header>
  #   """
  # end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id">{user.id}</:col>
        <:col :let={user} label="username">{user.username}</:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-11 sm:w-full">
        <thead class="text-sm text-left leading-6 text-zinc-500">
          <tr>
            <th :for={col <- @col} class="p-0 pb-4 pr-6 font-normal">{col[:label]}</th>
            <th :if={@action != []} class="relative p-0 pb-4">
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative divide-y divide-zinc-100 border-t border-zinc-200 text-sm leading-6 text-zinc-700"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-zinc-50">
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class="absolute -inset-y-px right-0 -left-4 group-hover:bg-zinc-50 sm:rounded-l-xl" />
                <span class={["relative", i == 0 && "font-semibold text-zinc-900"]}>
                  {render_slot(col, @row_item.(row))}
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-zinc-50 sm:rounded-r-xl" />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
                >
                  {render_slot(action, @row_item.(row))}
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  attr :id, :string, required: true

  slot :inner_block, required: true
  slot :content

  def dropdown(assigns) do
    ~H"""
    <div class="relative inline-block text-left" phx-click-away={hide_dropdown(@id)}>
      <%= render_slot(@inner_block, toggle: toggle_dropdown(@id)) %>

      <div
        id={@id}
        class="simple_budgeting dropdown hidden absolute right-0 z-10 mt-2 w-56 origin-top-right rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
      >
        <%= render_slot(@content, toggle: toggle_dropdown(@id)) %>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true

  slot :inner_block, required: true
  slot :menu

  def dropdown_with_button(assigns) do
    ~H"""
    <div class="inline-flex rounded-md shadow-sm" phx-click-away={hide_dropdown(@id)}>
      <%= render_slot(@inner_block) %>

      <div class="relative -ml-px block">
        <button
          type="button"
          class="relative inline-flex items-center rounded-r-md border border-gray-300 bg-white px-2 py-2 text-sm font-medium text-gray-500 hover:bg-gray-50 focus:z-10 focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
          id={"#{@id}-option-menu-button"}
          aria-expanded="true"
          aria-haspopup="true"
          phx-click={toggle_dropdown(@id)}
        >
          <span class="sr-only">Open options</span>
          <.icon name="hero-chevron-down" class="ml-2 w-5 h-5 fill-current" />
        </button>

        <div
          id={@id}
          class="simple_budgeting dropdown hidden absolute right-0 z-10 mt-2 w-56 origin-top-right rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
        >
          <%= render_slot(@menu) %>
        </div>
      </div>
    </div>
    """
  end

  attr :toggle, :any, required: true
  attr :label, :string, default: "Options"
  slot :inner_block

  def dropdown_button(assigns) do
    ~H"""
    <button
      type="button"
      class="inline-flex w-full justify-center rounded-md border border-gray-300 bg-white px-4 py-2 text-sm font-medium text-gray-700 shadow-sm hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 focus:ring-offset-gray-100"
      phx-click={@toggle}
    >
      <%= if @inner_block == [] do %>
        <%= @label %>
      <% else %>
        <%= render_slot(@inner_block) %>
      <% end %>
      <.icon name="hero-chevron-down" class="ml-2 w-5 h-5 fill-current" />
    </button>
    """
  end

  def hide_dropdown(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}",
      transition:
        {"transition ease-in duration-75", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    )
  end

  def toggle_dropdown(js \\ %JS{}, id) do
    js
    |> JS.toggle(
      to: "##{id}",
      in:
        {"transition ease-out duration-100", "transform opacity-0 scale-95",
         "transform opacity-100 scale-100"},
      out:
        {"transition ease-in duration-75", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    )
  end

  defp format_datetime(%Date{} = date, format) do
    date
    |> NaiveDateTime.new!(~T[05:00:00.000])
    |> format_datetime(format)
  end

  defp format_datetime(datetime, format) do
    # Ecto stores datetimes in naive format/UTC time, so we can convert that to DateTime with a proper timezone.
    DateTime.from_naive!(datetime, "Etc/UTC")
    |> DateTime.shift_zone!("America/New_York")
    |> Calendar.strftime(format)
  end

  defp maybe_add_timezone(format, include_timezone) do
    if include_timezone do
      format <> " %Z"
    else
      format
    end
  end

  attr :format, :string
  attr :date, :any, required: true
  attr :show_time, :boolean, default: false
  attr :include_timezone, :boolean, default: false

  def moment(%{format: _format} = assigns) do
    ~H"""
    <%= format_datetime(@date, @format) %>
    """
  end

  def moment(assigns) do
    ~H"""
    <%= if @show_time do %>
      <%= format_datetime(@date, "%d%b%Y") %> at <%= format_datetime(
        @date,
        maybe_add_timezone("%I:%M%p", @include_timezone)
      ) %>
    <% else %>
      <%= format_datetime(@date, "%d%b%Y") %>
    <% end %>
    """
  end

  attr :field, :atom, required: true
  slot(:inner_block, required: true)

  def map_inputs_for(assigns) do
    %Phoenix.HTML.FormField{field: field, form: form} = assigns.field
    name = to_string(form.name <> "[#{field}]")

    form =
      form.source
      |> Ecto.Changeset.get_field(field)
      |> to_form(as: name)

    assigns = assign(assigns, f_inner: form)

    ~H"""
    <%= render_slot(@inner_block, @f_inner) %>
    """
  end

  attr :combobox, :any, required: true
  attr :options, :list, required: true

  slot :inner_block, required: true
  slot :empty

  def combobox_options(assigns) do
    ~H"""
    <ul
      :if={@combobox.open}
      class="absolute z-10 mt-1 max-h-56 w-full overflow-auto rounded-md bg-white py-1 text-base shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none sm:text-sm"
      role="listbox"
    >
      <%= render_slot(@inner_block, @combobox.options) %>

      <%= if Enum.empty?(@combobox.options) do %>
        <li class="relative cursor-default select-none py-2 pl-3 pr-9">
          <%= render_slot(@empty) %>
        </li>
      <% end %>
    </ul>
    """
  end

  attr :combobox, :any, required: true
  attr :onclick, :any, required: true
  attr :key, :string, required: true
  attr :combobox_target, :any, required: true

  slot :inner_block, required: true

  def combobox_option(assigns) do
    ~H"""
    <li
      phx-click={@onclick |> JS.push("select-click", target: @combobox_target)}
      phx-value-key={@key}
      class={[
        "group relative cursor-default select-none py-2 pl-3 pr-9 hover:text-white hover:bg-blue-500",
        @combobox.selected_key == @key && "text-white bg-blue-600",
        @combobox.selected_key != @key && "text-gray-900"
      ]}
    >
      <%= render_slot(@inner_block, @combobox.selected_key == @key) %>
    </li>
    """
  end

  @doc """
  A tooltip component that allows a tooltip
  to appear over a target.

  ## Example

  <.tool_tip>
    <:target>
      Text that, when hovered over, will show tooltip
    </:target>
    <:tooltip>
      Tooltip text that will appear.
    </:tooltip>
  </.tool_tip>
  """
  attr :class, :string, default: ""

  slot :target, required: true
  slot :tooltip, required: true

  def tool_tip(assigns) do
    ~H"""
    <div class={["tooltip", @class]}>
      <%= render_slot(@target) %>
      <div class="tooltip-text">
        <%= render_slot(@tooltip) %>
      </div>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title">{@post.title}</:item>
        <:item title="Views">{@post.views}</:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-zinc-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-zinc-500">{item.title}</dt>
          <dd class="text-zinc-700">{render_slot(item)}</dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        {render_slot(@inner_block)}
      </.link>
    </div>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  def icon(%{name: "fa-user-robot"} = assigns) do
    ~H"""
    <span class="align-middle">
      <svg xmlns="http://www.w3.org/2000/svg" class={@class} fill="currentColor" viewBox="0 0 448 512">
        <path d="M17.99986,256H48V128H17.99986A17.9784,17.9784,0,0,0,0,146v92A17.97965,17.97965,0,0,0,17.99986,256Zm412-128H400V256h29.99985A17.97847,17.97847,0,0,0,448,238V146A17.97722,17.97722,0,0,0,429.99985,128ZM116,320H332a36.0356,36.0356,0,0,0,36-36V109a44.98411,44.98411,0,0,0-45-45H241.99985V18a18,18,0,1,0-36,0V64H125a44.98536,44.98536,0,0,0-45,45V284A36.03685,36.03685,0,0,0,116,320Zm188-48H272V240h32ZM288,128a32,32,0,1,1-32,32A31.99658,31.99658,0,0,1,288,128ZM208,240h32v32H208Zm-32,32H144V240h32ZM160,128a32,32,0,1,1-32,32A31.99658,31.99658,0,0,1,160,128ZM352,352H96A95.99975,95.99975,0,0,0,0,448v32a32.00033,32.00033,0,0,0,32,32h96V448a31.99908,31.99908,0,0,1,32-32H288a31.99908,31.99908,0,0,1,32,32v64h96a32.00033,32.00033,0,0,0,32-32V448A95.99975,95.99975,0,0,0,352,352ZM176,448a15.99954,15.99954,0,0,0-16,16v48h32V464A15.99954,15.99954,0,0,0,176,448Zm96,0a16,16,0,1,0,16,16A15.99954,15.99954,0,0,0,272,448Z" />
      </svg>
    </span>
    """
  end

  def icon(%{name: "fa-function"} = assigns) do
    ~H"""
    <span class="align-middle">
      <svg xmlns="http://www.w3.org/2000/svg" class={@class} fill="currentColor" viewBox="0 0 640 512">
        <path d="M288.73 320c0-52.34 16.96-103.22 48.01-144.95 5.17-6.94 4.45-16.54-2.15-22.14l-24.69-20.98c-7-5.95-17.83-5.09-23.38 2.23C246.09 187.42 224 252.78 224 320c0 67.23 22.09 132.59 62.52 185.84 5.56 7.32 16.38 8.18 23.38 2.23l24.69-20.99c6.59-5.61 7.31-15.2 2.15-22.14-31.06-41.71-48.01-92.6-48.01-144.94zM224 16c0-8.84-7.16-16-16-16h-48C102.56 0 56 46.56 56 104v64H16c-8.84 0-16 7.16-16 16v48c0 8.84 7.16 16 16 16h40v128c0 13.2-10.8 24-24 24H16c-8.84 0-16 7.16-16 16v48c0 8.84 7.16 16 16 16h16c57.44 0 104-46.56 104-104V248h40c8.84 0 16-7.16 16-16v-48c0-8.84-7.16-16-16-16h-40v-64c0-13.2 10.8-24 24-24h48c8.84 0 16-7.16 16-16V16zm353.48 118.16c-5.56-7.32-16.38-8.18-23.38-2.23l-24.69 20.98c-6.59 5.61-7.31 15.2-2.15 22.14 31.05 41.71 48.01 92.61 48.01 144.95 0 52.34-16.96 103.23-48.01 144.95-5.17 6.94-4.45 16.54 2.15 22.14l24.69 20.99c7 5.95 17.83 5.09 23.38-2.23C617.91 452.57 640 387.22 640 320c0-67.23-22.09-132.59-62.52-185.84zm-54.17 231.9L477.25 320l46.06-46.06c6.25-6.25 6.25-16.38 0-22.63l-22.62-22.62c-6.25-6.25-16.38-6.25-22.63 0L432 274.75l-46.06-46.06c-6.25-6.25-16.38-6.25-22.63 0l-22.62 22.62c-6.25 6.25-6.25 16.38 0 22.63L386.75 320l-46.06 46.06c-6.25 6.25-6.25 16.38 0 22.63l22.62 22.62c6.25 6.25 16.38 6.25 22.63 0L432 365.25l46.06 46.06c6.25 6.25 16.38 6.25 22.63 0l22.62-22.62c6.25-6.25 6.25-16.38 0-22.63z" />
      </svg>
    </span>
    """
  end

  def icon(%{name: "fa-code-branch"} = assigns) do
    ~H"""
    <span class="align-middle">
      <svg xmlns="http://www.w3.org/2000/svg" class={@class} fill="currentColor" viewBox="0 0 384 512">
        <path d="M384 144c0-44.2-35.8-80-80-80s-80 35.8-80 80c0 36.4 24.3 67.1 57.5 76.8-.6 16.1-4.2 28.5-11 36.9-15.4 19.2-49.3 22.4-85.2 25.7-28.2 2.6-57.4 5.4-81.3 16.9v-144c32.5-10.2 56-40.5 56-76.3 0-44.2-35.8-80-80-80S0 35.8 0 80c0 35.8 23.5 66.1 56 76.3v199.3C23.5 365.9 0 396.2 0 432c0 44.2 35.8 80 80 80s80-35.8 80-80c0-34-21.2-63.1-51.2-74.6 3.1-5.2 7.8-9.8 14.9-13.4 16.2-8.2 40.4-10.4 66.1-12.8 42.2-3.9 90-8.4 118.2-43.4 14-17.4 21.1-39.8 21.6-67.9 31.6-10.8 54.4-40.7 54.4-75.9zM80 64c8.8 0 16 7.2 16 16s-7.2 16-16 16-16-7.2-16-16 7.2-16 16-16zm0 384c-8.8 0-16-7.2-16-16s7.2-16 16-16 16 7.2 16 16-7.2 16-16 16zm224-320c8.8 0 16 7.2 16 16s-7.2 16-16 16-16-7.2-16-16 7.2-16 16-16z" />
      </svg>
    </span>
    """
  end

  ## JS Commands

  def push_hide_modal(socket, id) do
    Phoenix.LiveView.push_event(socket, "js-exec", %{
      to: "##{id}",
      attr: "data-hide-modal"
    })
  end

  def push_show_modal(socket, id) do
    Phoenix.LiveView.push_event(socket, "js-exec", %{
      to: "##{id}",
      attr: "data-show-modal"
    })
  end

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      time: 300,
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(SimpleBudgetingWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(SimpleBudgetingWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  attr :class, :string, default: nil
  attr :size, :string, default: "small"
  attr :color, :string, default: "gray"
  attr :label, :string, default: nil

  slot :inner_block

  def pill(assigns) do
    %{size: size, color: color} = assigns

    size_css =
      case size do
        "small" -> "text-sm px-3 py-1 font-medium"
        "medium" -> "text-base px-4 py-1 font-medium"
        "large" -> "text-xl px-9 py-3 font-bold"
        "xlarge" -> "text-xl px-9 py-3 font-bold"
      end

    color_css =
      case color do
        "red" -> "!bg-red-200 !text-red-900"
        "black" -> "!bg-black !text-white"
        "green" -> "!bg-green-200 !text-green-900"
        "yellow" -> "!bg-yellow-200 !text-yellow-900"
        "blue" -> "!bg-blue-300 !text-blue-900"
        "white" -> "!bg-white !text-gray-900"
        "gray" -> "!bg-gray-100 !text-gray-900"
        "dark-gray" -> "!bg-gray-300 !text-gray-900"
        "orange" -> "!bg-orange-300 !text-orange-900"
      end

    assigns =
      assigns
      |> assign(size_css: size_css)
      |> assign(color_css: color_css)

    ~H"""
    <span class={["mr-1 mb-1 rounded-full", @size_css, @color_css, @class]}>
      <%= if @inner_block != [] do %>
        <%= render_slot(@inner_block) %>
      <% else %>
        <%= @label %>
      <% end %>
    </span>
    """
  end

  attr :type, :string, required: true
  attr :title, :string, required: true
  attr :status, :string, default: nil

  slot :attribute

  def page_header(assigns) do
    ~H"""
    <div>
      <div class="text-gray-500 text-sm"><%= @type %></div>
      <h2 class="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:leading-9 sm:truncate">
        <%= @title %>
      </h2>
      <div class="text-gray-500 text-sm"><%= @status %></div>

      <%= if @attribute != [] do %>
        <div class="mt-1 flex flex-col sm:mt-0 sm:flex-row sm:flex-wrap">
          <%= for attr <- @attribute do %>
            <div class="mt-2 flex items-center text-sm leading-5 text-gray-600 sm:mr-6">
              <%= render_slot(attr) %>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :dl_class, :string, default: nil

  slot :title
  slot :description
  slot :inner_block, required: true

  def description_list(assigns) do
    ~H"""
    <section class={@class}>
      <%= if @title != [] do %>
        <h3 class="text-lg leading-6 font-medium text-gray-900">
          <%= render_slot(@title) %>
        </h3>
      <% end %>
      <%= if @description != [] do %>
        <p class="mt-1 max-w-2xl text-sm text-gray-500">
          <%= render_slot(@description) %>
        </p>
      <% end %>
      <div class={[@title != [] && "mt-5 border-t border-gray-200"]}>
        <dl class={["divide-y divide-gray-200", @dl_class]}>
          <%= render_slot(@inner_block) %>
        </dl>
      </div>
    </section>
    """
  end

  attr :class, :string, default: nil
  slot :label, required: true
  slot :inner_block, required: true

  def description_list_row(assigns) do
    ~H"""
    <div class={["py-2 sm:py-3 sm:grid sm:grid-cols-4 sm:gap-4", @class]}>
      <dt class="text-base font-medium text-gray-500">
        <%= render_slot(@label) %>
      </dt>
      <dd class="mt-1 text-base text-gray-900 sm:mt-0 sm:col-span-3">
        <%= render_slot(@inner_block) %>
      </dd>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :table_class, :string, default: nil
  attr :queryable, :any, required: true
  attr :page, :integer, default: 1
  attr :per_page, :integer, default: 25
  attr :prefix, :any, default: nil
  attr :now, :any, default: nil
  attr :preload, :list, default: []
  attr :repo, :any, default: SimpleBudgeting.Repo
  attr :with_index, :boolean, default: false
  attr :paginate, :string, required: true
  attr :condensed, :boolean, default: false

  slot :header, required: true
  slot :row, required: true

  def paged_table(assigns) do
    %{
      queryable: queryable,
      preload: preload,
      page: page,
      prefix: prefix,
      per_page: per_page,
      repo: repo,
      with_index: with_index
    } = assigns

    paged =
      SimpleBudgeting.Utils.Paged.paginate(queryable,
        preload: preload,
        prefix: prefix,
        page: page,
        per_page: per_page,
        repo: repo
      )

    records =
      if with_index do
        starting_index = (page - 1) * per_page
        Enum.with_index(paged.records, starting_index)
      else
        paged.records
      end

    assigns =
      assigns
      |> assign(paged: paged)
      |> assign(records: records)

    ~H"""
    <section class={["w-full", @class]}>
      <span class="hidden" :if={@now}><.moment date={@now} /></span>
      <.paged_pagination paged={@paged} page={@page} paginate={@paginate} />

      <div class={[
        "shadow ring-1 ring-black ring-opacity-5 md:rounded-lg",
        @table_class
      ]}>
        <table class={[
          "simple_budgeting table",
          @condensed && "condensed"
        ]}>
          <thead>
            <%= render_slot(@header) %>
          </thead>
          <tbody>
            <%= for record <- @records do %>
              <%= render_slot(@row, record) %>
            <% end %>
          </tbody>
        </table>
      </div>

      <.paged_pagination paged={@paged} page={@page} paginate={@paginate} />
    </section>
    """
  end

  attr :class, :string, default: nil
  attr :table_class, :string, default: nil
  attr :queryable, :any, required: true
  attr :page, :integer, default: 1
  attr :per_page, :integer, default: 25
  attr :prefix, :any, default: nil
  attr :preload, :list, default: []
  attr :repo, :any, default: SimpleBudgeting.Repo
  attr :paginate, :string

  slot :inner_block, required: true

  def paged_records(assigns) do
    %{
      queryable: queryable,
      preload: preload,
      page: page,
      prefix: prefix,
      per_page: per_page,
      repo: repo
    } = assigns

    paged =
      SimpleBudgeting.Utils.Paged.paginate(queryable,
        preload: preload,
        prefix: prefix,
        page: page,
        per_page: per_page,
        repo: repo
      )

    assigns = assign(assigns, paged: paged)

    ~H"""
    <section class={["w-full", @class]}>
      <.paged_pagination paged={@paged} page={@page} paginate={@paginate} />

      <%= render_slot(@inner_block, @paged.records) %>

      <%= if @paged.total_count > 0 do %>
        <.paged_pagination paged={@paged} page={@page} paginate={@paginate} />
      <% end %>
    </section>
    """
  end

  attr :paged, :any, required: true
  attr :page, :integer, required: true
  attr :paginate, :string, required: true

  def paged_pagination(assigns) do
    ~H"""
    <nav class="py-3 flex items-end justify-between">
      <div class="hidden sm:block">
        <p class="text-sm text-gray-700">
          Showing <span class="font-medium"><%= @paged.starting_at %></span>
          to <span class="font-medium"><%= @paged.ending_at %></span>
          of <span class="font-medium"><%= @paged.total_count %></span>
          results
        </p>
      </div>
      <div class="flex-1 flex justify-between sm:justify-end">
        <%= if @page > 1 do %>
          <a
            phx-click={@paginate}
            phx-value-page={@page - 1}
            class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 cursor-pointer"
          >
            Previous
          </a>
        <% end %>
        <%= if @paged.ending_at != @paged.total_count do %>
          <a
            phx-click={@paginate}
            phx-value-page={@page + 1}
            class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 cursor-pointer"
          >
            Next
          </a>
        <% end %>
      </div>
    </nav>
    """
  end

  attr :id, :string, required: true
  attr :confirm_text, :string, default: "Confirm"
  attr :title, :string, default: "Confirm?"
  attr :on_confirm, :any, required: true

  slot :inner_block

  def confirm_danger_modal(assigns) do
    ~H"""
    <.modal id={"#{@id}_modal"}>
      <:title>
        <%= @title %>
      </:title>

      <%= render_slot(@inner_block) %>

      <:footer>
        <button type="button" phx-click={@on_confirm} class="simple_budgeting primary button">
          <%= @confirm_text %>
        </button>
      </:footer>
    </.modal>
    """
  end

  attr :id, :string, required: true
  attr :expanded, :boolean, default: false

  slot :header
  slot :inner_block

  def expandable_section(assigns) do
    ~H"""
    <.live_component
      id={@id}
      module={SimpleBudgetingWeb.Components.ExpandableSection}
      expanded={@expanded}
      header={@header}
      inner_block={@inner_block}
    />
    """
  end

  attr :id, :string, required: true
  attr :data, :any, default: []
  attr :width, :integer, default: 1460
  attr :height, :integer, default: 400

  def bar_plot_stacked_percent(assigns) do
    ~H"""
    <.live_component
      id={"#{@id}_component"}
      module={SimpleBudgetingWeb.Index.AmountPieChart}
      data={@data}
      width={@width}
      height={@height}
    />
    """
  end

  @doc """
  Renders a card.
  """
  attr :class, :string, default: nil
  attr :rest, :global, include: slot(:inner_block, required: true)
  slot :header
  slot :footer

  def card(assigns) do
    ~H"""
    <div
      class={["bg-white border border-gray-200 overflow-visible shadow rounded-lg", @class]}
      {@rest}
    >
      <%= if Enum.any?(@header) do %>
        <div class="bg-white px-4 py-5 border-b border-b-gray-200 sm:px-6 border-l-[6px] !border-emerald-500 rounded-t-lg">
          <%= render_slot(@header) %>
        </div>
      <% end %>

      <div class="px-6 py-2">
        <%= render_slot(@inner_block, class: "px-4 py-5 sm:p-6") %>
      </div>

      <div :if={@footer} class="bg-gray-50 px-4 py-2 sm:px-6">
        <%= render_slot(@footer) %>
      </div>
    </div>
    """
  end

  #### EVERYTHING BELOW FROM: https://github.com/brainlid/langchain_demo

  @doc """
  Render the raw content as markdown. Returns HTML rendered text.
  """
  def render_markdown(nil), do: Phoenix.HTML.raw(nil)

  def render_markdown(text) when is_binary(text) do
    # NOTE: This allows explicit HTML to come through.
    #   - Don't allow this with user input.
    text |> Earmark.as_html!(escape: false) |> Phoenix.HTML.raw()
  end

  @doc """
  Render a markdown containing web component.
  """
  attr :text, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global

  def markdown(%{text: nil} = assigns), do: ~H""

  def markdown(assigns) do
    ~H"""
    <div class={["prose dark:prose-invert", @class]} {@rest}><%= render_markdown(@text) %></div>
    """
  end
  attr :role, :atom, required: true

  def icon_for_role(assigns) do
    icon_name =
      case assigns.role do
        :assistant ->
          "hero-computer-desktop"

        :tool ->
          "hero-cog-8-tooth"

        _other ->
          "hero-user"
      end

    assigns = assign(assigns, :icon_name, icon_name)

    ~H"""
    <.icon name={@icon_name} />
    """
  end

  attr :id, :string, required: true
  attr :chain, :any, required: true
  attr :call, :any, required: true
  attr :class, :string, default: nil

  def call_display_name(assigns) do
    call = assigns.call
    chain = assigns.chain

    text =
      LangChain.Function.get_display_text(
        chain.tools,
        call.name,
        "Call tool #{call.name}"
      )

    assigns = assign(assigns, :text, text)

    ~H"""
    <div id={@id} class={["font-medium text-gray-700", @class]}>
      <div><%= @text %></div>
    </div>
    """
  end

  attr :call, :any, required: true

  def get_tool_call_display(assigns) do
    ~H"""
    <div class="text-gray-700">
      <div class="block text-sm font-medium text-gray-700">Tool Name:</div>
      <div class="mt-2 text-gray-600 font-mono"><%= @call.name %></div>

      <div class="mt-4 block text-sm font-medium text-gray-700">Arguments:</div>
      <pre class="mt-2 px-4 py-2 bg-slate-700 text-gray-100 rounded-md"><code class="text-wrap"><%= inspect(@call.arguments) %></code></pre>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :chain, :any, required: true
  attr :result, :any, required: true
  attr :class, :string, default: nil

  def tool_result_display_name(assigns) do
    chain = assigns.chain
    text = LangChain.Function.get_display_text(chain.tools, assigns.result.name, "Perform action")
    assigns = assign(assigns, :text, text)

    ~H"""
    <span id={@id} class={@class}><%= @text %></span>
    """
  end

  attr :result, :any, required: true

  def tool_result_detail_display(assigns) do
    ~H"""
    <div class="text-gray-700">
      <div class="block text-sm font-medium text-gray-700">Tool Name:</div>
      <div class="mt-2 text-gray-600 font-mono"><%= @result.name %></div>

      <div class="mt-4 block text-sm font-medium text-gray-700">Content:</div>
      <pre class="mt-2 px-4 py-2 bg-slate-700 text-gray-100 rounded-md"><code class="text-wrap"><%= inspect(@result.content) %></code></pre>
    </div>
    """
  end
end
