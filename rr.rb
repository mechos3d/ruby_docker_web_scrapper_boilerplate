require 'faraday'
require 'faraday-cookie_jar'

class GlassDoorScrapper

  def call
    conn = Faraday.new(:url => "https://www.glassdoor.com/") do |builder|
      builder.use :cookie_jar
      builder.adapter Faraday.default_adapter
    end

    res1 = conn.get('index.htm')
    # conn.get "/bar"  # sends cookie

    require 'pry'; binding.pry
  end

end


GlassDoorScrapper.new.call
