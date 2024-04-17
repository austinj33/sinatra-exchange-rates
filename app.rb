require "sinatra"
require "sinatra/reloader" if development?
require "http"
require "json"

configure do
  set :tickers, []
end

def update_tickers
  access_key = ENV.fetch("EXCHANGE_RATE_KEY", 'your_default_access_key')
  exchange_rate_url = "https://api.exchangerate.host/list?access_key=#{access_key}"

  response = HTTP.get(exchange_rate_url)
  raise "Failed to fetch data" unless response.status.success?

  parsed_data = JSON.parse(response.to_s)

  if parsed_data["success"]
    currencies = parsed_data["currencies"]
    settings.tickers.replace(currencies.keys)
  else
    puts "API Error: #{parsed_data["error"]["info"] if parsed_data["error"]}"
  end
end

before do
  update_tickers if settings.tickers.empty?
end

get "/" do
  @list_items = settings.tickers.map { |ticker|
    "<li><a href=\"/#{ticker}\">Convert 1 #{ticker} to...</a></li>"
  }
  erb :home_page
end

get "/:ticker" do
  @ticker = params[:ticker]
  @other_tickers = settings.tickers.reject { |t| t == @ticker }
  @conversion_list = @other_tickers.map { |other_ticker|
    "<li><a href=\"/#{@ticker}/#{other_ticker}\">Convert 1 #{@ticker} to #{other_ticker}...</a></li>"
  }
  erb :currency_page
end

get "/:ticker1/:ticker2" do
  @ticker1 = params[:ticker1]
  @ticker2 = params[:ticker2]
  access_key = ENV.fetch("EXCHANGE_RATE_KEY", 'your_default_access_key')
  amount = 1  # Hard-code the amount to 1
  quote_url = "https://api.exchangerate.host/convert?access_key=#{access_key}&from=#{@ticker1}&to=#{@ticker2}&amount=#{amount}"

  response = HTTP.get(quote_url)
  parsed_data = JSON.parse(response.to_s)

  if parsed_data["success"]
    @result = parsed_data["result"]
    @quote_message = "1 #{@ticker1} equals #{@result} #{@ticker2}."
  else
    @quote_message = "No quote available for #{@ticker1} to #{@ticker2}."
  end

  erb :quote_page
end
