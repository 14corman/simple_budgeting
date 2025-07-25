# SimpleBudgeting

I wanted a simple budgeting application that I controlled locally. No 3rd party sending financial records to, nothing linking my bank accounts. Everything I control locally, and that is what I built here. A simple application where you put in your transactions, what budget they apply to, and what location they occurred at. Over time, you are able to get an easy sense of your budget.

Because I made this specifically for me, there are a list of things I set up for my situation:
  - I did not add a login or passwords since I have mine behind a SSO proxy which does that for me.
  - I added charts and explanations based on how I wanted to see things.
  - I focused on elements of the application that I wanted to set up based on the limited time I had.
  - I did not spend time adding tests because I was the only one using this application locally

With this application being pushed up to Github, if there is something you would like to see set up, fixed, or adjusted, feel free to make a PR or a new issue. I have limited time to work on this, so I would welcome PRs.

## Descriptions
  - Account: An account that holds money (EX: HSA, Savings account, Checking account, stock, etc)
  - Budget: Something you set up based on your needs (EX: Home, Personal, Food, Transportation, Entertainment, etc). These linke to an account.
  - Location: The location a transaction takes place (EX: StarBucks, Mcdonalds, Walmart, ISP, etc)
  - Receipt Source: Places that create the transaction (EX: Bank where you swipe credit/debit card, Credit card, HSA Card, etc)
  - Transaction: The item that links everything together. An actual transaction (EX: Bought coffee at StarBucks for $4.95 on 7/3/2024 using credit card).

## Types of transactions
  - Normal transaction: One receipt gets made into 1 transaction
  - Compound transaction: One receipt gets made into 2+ transactions (This can be helpful if you buy multiple types of things at a store and want to itemize. EX: Food and clothes at walmart)
  - Paycheck: You put in the amount of the paycheck and where it came from. The system then uses the percentages you gave all the budgets to divide the paycheck into pieces for each budget based on its percentage.

## Budget percentages
When you put in a paycheck, the budget percentages tell what percentage of that paycheck goes into the respective budget. **All budget percentages must add up to 100%**. This is enforced when the user goes to the Budgets > Balance budgets page. There, you can put in test monthly incomme amounts, along with transactional information, to get a good idea of how much percentage should go towards each budget.

## Extras (Save points, Dashboard, and AI)
There are a few extra things within this application.
  1. The dashboard gives you a high level overview of your budget amounts, total current funds, and what your total funds look like over the last year.
  2. A **Conversational AI** through Ollama. This is just an extra piece I added since the AI was already there for the Agent. You can make and save conversations similar to ChatGPT. Best part, it is all local.
  3. **SimpleBudgeting AI (SBAI)** is an AI Agent that has functions to look into your finances to answer questions you might have. This uses Ollama library with whichever llama LLM you want to use.
  4. Save and restore points. If you are like me and are parinoid about data loss, this is for you. Under Transactions > Options, you can create save and restore save. Creating a save makes a dump of the database and saves it locally to `./db_backups/[year]/`. This way, if something happens with the docker volume that holds the database, you cannot seem to balance anything no matter how hard you try, something gets corrupted, or you want to save these backups offsight with encryption, you can do that. That way, you can rest assured the database is backed up. I personally create a new save every time I add new transactions to the application. **This is not an automated process.** You must save restore points manually. I did this because I want to make sure my transactions are in a spot I want before a save occurrs. I also want to save whether I was able to balance the budgets or not. That way, if I forget later, I can check and I can also roll back to a previously balanced state if needed.

# Running the application
This runs through Docker, Elixir, Phoenix, PostgreSQL, and Ollama. Everything runs behind Docker, but you still need to download the Llama model (if you plan on using it). If you do not care about the AI, you can skip step 1 and move on to step 2.
  1. Download a Llama model (I have used llama3.1 8b) through whichever means you prefer. You can use [HuggingFace](https://huggingface.co/meta-llama/Llama-3.1-8B-Instruct) or you can download it through a tool like [Ollama Docker](https://github.com/mythrantic/ollama-docker) to find and test a model that works well for you locally using Ollama-webui. You can download and test models there, then copy the model to `./ollama/ollama/models` directory.
  2. Run `docker compose run app mix setup`. This will:
    1. Pull all needed images
    2. Build the app image
    3. Download all Elixir and npm modules/libraries
    4. Set up the databases using Ecto

After that, you can run `docker compose up` and the server, Ollama, and postgres will start. From there, you can go to `http://localhost:4000` to access the application. In my setup, I have it behind a proxy on a different computer, so I can go to something like the following example `https://budget.something.come` to access the application.

# LLM usage
- LLM system is running on Ollama
- Elixir library used to query Ollama instance and run functions is [LangChain](). We use version 0.3.3 rather than the 0.4.x release candidates due to Ollama issues with streaming and function calling. At the time of writing this, there was a recent PR merged, in the last month, that allowed Ollama useage by adding `verbose_api`. However, streaming still does not work, and Ollama tool calls and results are not currently being parsed as `ToolCalls` like the `LangChain.Chains.LLMChain` module expects. I was able to code around the ToolCalls issue by modifying LMMChain code to check if a function call returns a JSON and if it does then parse it into a ToolCall, but that is not the proper way it should be done. Because of that, I moved back to 0.3.3.
- Basis for conversation and agent webpages came from [LangChain Demo](https://github.com/brainlid/langchain_demo). There were modifications I had to make to make the demo work in FireFox and for updated versions of Pheonix. For example, the ctr+enter hook had to have `cancel: true` added alongside bubble. Otherwise, FireFox would run the URL and break the websocket. Another example of a fix was the JS calls to show and hide the tool calls and results. I had to change those from a list of ids to 2 JS calls with 1 id each.
