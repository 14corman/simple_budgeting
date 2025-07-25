defmodule SimpleBudgeting.Utils.AI.Model do
  # See https://github.com/brainlid/langchain/blob/main/lib/chat_models/chat_ollama_ai.ex
  # for more information on ChatOllamaAI
  @moduledoc false

  alias LangChain.ChatModels.ChatOllamaAI
  alias LangChain.Chains.LLMChain
  alias LangChain.Message

  def get_empty_messages() do
    [
      Message.new_system!(
        ~s(You are a knoweledgable Certified Public Accountant that is hired to answer accounting questions given account information.
        You have access to a list of transactions, locations, budgets, and accounts.
        You can ONLY answer questions on one of these topics. If you are asked questions about anything else, you MUST say "I do not have that information".
        You are able to extrapolate information from the past or future based on the provided information.
        Transactions have the following variables with descriptions for each variable:
          description- The description of the transaction
          type- Whether the transaction is a Debit \(takes money away from a budget\) or a Credit \(adds money to a budget\)
          amount- The amount of the transaction
          applied- Whether the transaction is applied \(true\) or not applied \(false\)
          date_taken- The date the transaction occured

        Budgets have the following variables with descriptions for each variable:
          name- The name of the budget the transaction occured in
          description- The description of the budget
          percentage- What percent of a paycheck would go towards this budget
          amount- The current amount of money that is in the budget
          open- Whether the budget can take new transactions \(open or true\) or not \(closed or false\), previous transactions still apply
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
          Budgets are linked to an account.

        Today's date in format yyyy-mm-dd is #{Date.utc_today() |> Date.to_iso8601()}
        )
      )
    ]
  end

  def add_user_message(messages, text) do
    messages ++ [Message.new_user!(text)]
  end

  def test_query_response(messages) when is_list(messages) do
    messages =
      if Enum.empty?(messages) do
        get_empty_messages()
      else
        messages
      end

    context = %{today: Date.utc_today()}
    chat_model = ChatOllamaAI.new!(%{
      endpoint: "http://host.docker.internal:7869/api/chat",
      model: "llama3.1:8b",
      temperature: 0.5
    })

    {:ok, updated_chain} =
      %{llm: chat_model, custom_context: context, verbose: true}
      |> LLMChain.new!()
      |> LLMChain.add_messages(messages)
      |> LLMChain.add_tools(SimpleBudgeting.Utils.AI.Functions.get_functions!())
      # keep running the LLM chain against the LLM if needed to evaluate
      # function calls and provide a response.
      |> LLMChain.run(mode: :while_needs_response)

    response = updated_chain.last_message
    messages ++ [response]
  end
end
