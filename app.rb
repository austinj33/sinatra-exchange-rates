require "sinatra"
require "sinatra/reloader"
require "http"
require "json"

get "/" do
  access_key = ENV.fetch("EXCHANGE_RATE_KEY")
  exchange_rate_url = "https://api.exchangerate.host/latest?access_key=#{access_key}"


  begin
    # Fetching data from the exchange rate API
    response = HTTP.get(exchange_rate_url)
    raise "Failed to fetch data" unless response.status.success?

    # Parsing the JSON response
    parsed_data = JSON.parse(response.body.to_s)

    # Extract rates or other relevant data
    rates = parsed_data["rates"]
    @base_currency = parsed_data["base"]

    # You can use `@rates` and `@base_currency` in your ERB template
    erb :home_page
  rescue => e
    # Log the error or notify someone
    "Error: #{e.message}"
  end
end
