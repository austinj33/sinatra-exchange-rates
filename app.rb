require "sinatra"
require "sinatra/reloader" if development?
require "http"
require "json"

# Assume 'tickers' is global for the sake of simplicity. In production, you would want to avoid this.
tickers = []

# Fetches the tickers once when the server starts
before do
  if tickers.empty?
    access_key = ENV.fetch("EXCHANGE_RATE_KEY")
    exchange_rate_url = "https://api.exchangerate.host/latest?access_key=#{access_key}"

    response = HTTP.get(exchange_rate_url)
    raise "Failed to fetch data" unless response.status.success?

    # Parsing the JSON response
    parsed_data = JSON.parse(response.to_s)

    # Accessing the currencies data
    currencies = parsed_data.fetch("rates", {}) # It's usually 'rates', not 'currencies'

    # Update the tickers array with the new data
    tickers.replace(currencies.keys)
  end
end

# Route to display the main page with all currencies
get "/" do
  list_items = tickers.map { |ticker| "<li><a href=\"/#{ticker}\">Convert 1 #{ticker} to...</a></li>" }.join
  "<ul>#{list_items}</ul>"
end

# Generate dynamic routes for each ticker
tickers.each do |ticker1|
  get "/#{ticker1}" do
    other_tickers = tickers.reject { |t| t == ticker1 }
    list_items = other_tickers.map { |ticker2| "<li>Convert 1 #{ticker1} to #{ticker2}</li>" }.join
    "<ul>#{list_items}</ul>"
  end
end

