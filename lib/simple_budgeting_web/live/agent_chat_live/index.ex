defmodule SimpleBudgetingWeb.AgentChatLive.Index do
  use SimpleBudgetingWeb, :live_view

  require Logger
  alias Phoenix.LiveView.AsyncResult
  alias SimpleBudgetingWeb.AgentChatLive.Agent.ChatMessage
  alias LangChain.Chains.LLMChain
  alias LangChain.Message
  alias LangChain.ChatModels.ChatOllamaAI
  alias LangChain.PromptTemplate
  alias LangChain.LangChainError
  alias LangChain.Message.ToolCall

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    socket =
      socket
      # display a prompt message for the UI that isn't used in the actual
      # conversations
      |> assign(:display_messages, [
        %ChatMessage{
          role: :assistant,
          hidden: false,
          content:
            "Hello! My name is Sam and I'm your personal CPA! How can I help you today?"
        }
      ])
      |> reset_chat_message_form()
      |> assign_llm_chain()
      |> assign(:async_result, %AsyncResult{})

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"chat_message" => params}, socket) do
    changeset =
      params
      |> ChatMessage.create_changeset()
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"chat_message" => params}, socket) do
    socket =
      case ChatMessage.new(params) do
        {:ok, %ChatMessage{} = message} ->
          socket
          |> add_user_message(message.content)
          |> reset_chat_message_form()
          |> run_chain()

        {:error, changeset} ->
          assign_form(socket, changeset)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:chat_delta, %LangChain.MessageDelta{} = delta}, socket) do
    # This is where LLM generated content gets processed and merged to the
    # LLMChain managed by the state in this LiveView process.

    # Apply the delta message to our tracked LLMChain. If it completes the
    # message, display the message
    updated_chain = LLMChain.apply_delta(socket.assigns.llm_chain, delta)
    # if this completed the delta, create the message and track on the chain
    socket =
      if updated_chain.delta == nil do
        # the delta completed the message. Examine the last message
        message = updated_chain.last_message

        append_display_message(socket, %ChatMessage{
          role: message.role,
          content: message.content,
          tool_calls: message.tool_calls,
          tool_results: message.tool_results
        })
      else
        socket
      end

    {:noreply, assign(socket, :llm_chain, updated_chain)}
  end

  def handle_info({:tool_executed, tool_message}, socket) do
    message = %ChatMessage{
      role: tool_message.role,
      hidden: false,
      content: nil,
      tool_results: tool_message.tool_results
    }

    socket =
      socket
      |> assign(:llm_chain, LLMChain.add_message(socket.assigns.llm_chain, tool_message))
      |> append_display_message(message)

    {:noreply, socket}
  end

  # def handle_info({:updated_current_user, updated_user}, socket) do
  #   socket =
  #     socket
  #     |> assign(:current_user, updated_user)
  #     |> assign(
  #       :llm_chain,
  #       LLMChain.update_custom_context(socket.assigns.llm_chain, %{current_user: updated_user})
  #     )

  #   {:noreply, socket}
  # end

  def handle_info({:task_error, reason}, socket) do
    socket = put_flash(socket, :error, "Error with chat. Reason: #{inspect(reason)}")
    {:noreply, socket}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  @impl true
  @doc """
  Handles async function returning a successful result
  """
  def handle_async(:running_llm, {:ok, :ok = _success_result}, socket) do
    # discard the result of the successful async function. The side-effects are
    # what we want.
    socket =
      socket
      |> assign(:async_result, AsyncResult.ok(%AsyncResult{}, :ok))

    {:noreply, socket}
  end

  # handles async function returning an error as a result
  def handle_async(:running_llm, {:ok, {:error, reason}}, socket) do
    socket =
      socket
      |> put_flash(:error, reason)
      |> assign(:async_result, AsyncResult.failed(%AsyncResult{}, reason))

    {:noreply, socket}
  end

  # handles async function exploding
  def handle_async(:running_llm, {:exit, reason}, socket) do
    socket =
      socket
      |> put_flash(:error, "Call failed: #{inspect(reason)}")
      |> assign(:async_result, %AsyncResult{})

    {:noreply, socket}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  # if this is the FIRST user message, use a prompt template to include some
  # initial hidden instructions. We detect if it's the first by matching on the
  # last_messaging being the "system" message.
  def add_user_message(
        %{assigns: %{llm_chain: %LLMChain{last_message: %Message{role: :system}} = llm_chain}} =
          socket,
        user_text
      )
      when is_binary(user_text) do
    # current_user = socket.assigns.current_user
    today = Date.utc_today()

    current_user_template =
      PromptTemplate.from_template!(~S|
Today's date in format yyyy-mm-dd is <%= @today %>

Do an overview of my finances based on my budget amounts and transaction history over the last 5 months.

User says:
<%= @user_text %>|)

    updated_chain =
      llm_chain
      |> LLMChain.add_message(
        PromptTemplate.to_message!(current_user_template, %{
          today: today |> Date.to_iso8601(),
          user_text: user_text
        })
      )

    socket
    |> assign(llm_chain: updated_chain)
    # display what the user said, but not what we sent.
    |> append_display_message(%ChatMessage{role: :user, content: user_text})
  end

  def add_user_message(socket, user_text) when is_binary(user_text) do
    # NOT the first message. Submit the user's text as-is.
    updated_chain = LLMChain.add_message(socket.assigns.llm_chain, Message.new_user!(user_text))

    socket
    |> assign(llm_chain: updated_chain)
    |> append_display_message(%ChatMessage{role: :user, content: user_text})
  end

  defp assign_llm_chain(socket) do
    live_view_pid = self()

    handlers = %{
      on_llm_new_delta: fn _chain, %LangChain.MessageDelta{} = delta ->
        send(live_view_pid, {:chat_delta, delta})
      end,
      # record tool result
      on_tool_response_created: fn _chain, %LangChain.Message{role: :tool} = message ->
        tool_calls =
          message.tool_calls
          |> Enum.with_index()
          |> Enum.map(fn
            {%ToolCall{} = call, _index} -> call
            {function_map, index} ->
              call = Map.put(function_map, "call_id", index)
              ToolCall.new!(call)
          end)
        message = %LangChain.Message{message | tool_calls: tool_calls}
        send(live_view_pid, {:tool_executed, message})
      end
    }

    llm_chain =
      LLMChain.new!(%{
        llm:
          ChatOllamaAI.new!(%{
            endpoint: "http://host.docker.internal:7869/api/chat",
            model: "llama3.1:8b",
            temperature: 0,
            receive_timeout: 60_000,
            stream: true,
            num_predict: 1_500
          }),
        custom_context: %{
          live_view_pid: self(),
          today: Date.utc_today()
        },
        verbose: false
      })
      |> LLMChain.add_callback(handlers)
      |> LLMChain.add_tools(SimpleBudgeting.Utils.AI.Functions.get_functions!())
      |> LLMChain.add_message(Message.new_system!(~S|
Your name is SBAI. You are a knoweledgable Certified Public Accountant (CPA) that is hired to answer accounting questions given account information.
You have access to a list of transactions, locations, budgets, and accounts.
You can ONLY answer questions on one of these topics. If you are asked questions about anything else, you MUST say "I do not have that information".
You are able to extrapolate information from the past or future based on the provided information.
Transactions have the following variables with descriptions for each variable:
  description- The description of the transaction
  type- Whether the transaction is a Debit (takes money away from a budget) or a Credit (adds money to a budget)
  amount- The amount of the transaction
  applied- Whether the transaction is applied (true) or not applied (false)
  date_taken- The date the transaction occured

Budgets have the following variables with descriptions for each variable:
  name- The name of the budget the transaction occured in
  description- The description of the budget
  percentage- What percent of a paycheck would go towards this budget
  amount- The current amount of money that is in the budget
  open- Whether the budget can take new transactions (open or true) or not (closed or false), previous transactions still apply
  closed_on- What date the transcation was closed

Locations have the following variables with descriptions for each variable:
  name- The location name that the transaction took place at
  description- The description of that location

Accounts have the following variables with descriptions for each variable:
  name- The account that the budget is associated with
  description- The description of the account

Other pieces of information to know regarding this data are the following points:
  A budget will only be changed by a transaction if that transaction is applied.
  You determine the amount of money that an account currently has by adding up all budget amounts.
  When working on budgets, it is important to only look at the most recent transaction to get that budget's information.
  Transactions are linked to both a location and a budget.
  Budgets are linked to an account.|))

    socket
    |> assign(:llm_chain, llm_chain)
  end

  def run_chain(socket) do
    chain = socket.assigns.llm_chain

    socket
    |> assign(:async_result, AsyncResult.loading())
    |> start_async(:running_llm, fn ->
      case LLMChain.run(chain, mode: :while_needs_response) do
        # Don't return a large success result. Callbacks return what we want.
        {:ok, _updated_chain} ->
          :ok

        # return the errors for display
        {:error, _update_chain, %LangChainError{} = error} ->
          Logger.error("Received error when running the chain: #{error.message}")
          {:error, error.message}
      end
    end)
  end

  defp reset_chat_message_form(socket) do
    changeset = ChatMessage.create_changeset(%{})
    assign_form(socket, changeset)
  end

  defp append_display_message(socket, %ChatMessage{} = message) do
    assign(socket, :display_messages, socket.assigns.display_messages ++ [message])
  end
end
