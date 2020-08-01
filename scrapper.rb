# LINKS:
# https://medium.com/wolox/web-scraping-automation-with-selenium-and-ruby-8211e4573187
# https://tecadmin.net/setup-selenium-chromedriver-on-ubuntu/
# https://medium.com/@cesargralmeida/using-selenium-chrome-driver-and-capybara-to-automate-web-only-reports-7ffda7dfb83e

require 'selenium-webdriver'

class Scrapper
  def call
    # @wait = Selenium::WebDriver::Wait.new(timeout: 10) # seconds

    # TODO: '--no-sandbox' supposedly needed just because Chrome is run under 'root' here.
    # But running with --no-sandbox is discouraged.
    # It's worth trying running this ruby script under non-root user without '--no-sandbox'
    #
    # (Or not. There's an issue with running it in Docker):
    # https://bugs.chromium.org/p/chromedriver/issues/detail?id=2473
    opts = Selenium::WebDriver::Chrome::Options.new(
      args: ['--headless', '--no-sandbox', '--disable-dev-shm-usage']
    )

    driver = Selenium::WebDriver.for(:chrome, options: opts)

    driver.get 'https://google.com'

    puts driver.page_source

    driver.quit # Close browser when the task is completed
  end
end

Scrapper.new.call
