# LINKS:
# https://medium.com/wolox/web-scraping-automation-with-selenium-and-ruby-8211e4573187
# https://tecadmin.net/setup-selenium-chromedriver-on-ubuntu/
# https://medium.com/@cesargralmeida/using-selenium-chrome-driver-and-capybara-to-automate-web-only-reports-7ffda7dfb83e

require 'selenium-webdriver'

class Scrapper
  def call
    wait = Selenium::WebDriver::Wait.new(timeout: 5) # seconds

    # TODO: '--no-sandbox' supposedly needed just because Chrome is run under 'root' here.
    # But running with --no-sandbox is discouraged.
    # It's worth trying running this ruby script under non-root user without '--no-sandbox'
    #
    # (Or not. There's an issue with running it in Docker):
    # https://bugs.chromium.org/p/chromedriver/issues/detail?id=2473
    opts = Selenium::WebDriver::Chrome::Options.new(
      args: ['--headless', '--no-sandbox', '--disable-dev-shm-usage', '--window-size=1920,1080']
    )

    driver = Selenium::WebDriver.for(:chrome, options: opts)

    ## google.com  example: (Non-SPA) : --------------------------------------------------------
    # driver.get 'https://www.google.com'

    # element = wait.until do # Wait was defined in the initalize method of the main class, if it takes more than 10s to find the element, something went wrong
    #   driver.find_element(name: 'q')
    # end
    # element.send_keys 'ruby'
    # element.submit

    # puts driver.page_source
    ## google.com  example: -----------------------------------------------------------------

    driver.get 'https://www.glassdoor.com/profile/login_input.htm'

    element = wait.until do
      driver.find_element(id: 'userEmail')
    end
    element.send_keys(ENV.fetch('login'))
    element.submit

    element = wait.until { driver.find_element(id: 'userPassword') }
    element.send_keys(ENV.fetch('password'))
    element.submit

    element = wait.until { driver.find_element(name: 'submit') }
    element.click

    sleep(0.2)

    element = wait.until { driver.find_element(id: 'sc.location') }
    element.clear

    element = wait.until { driver.find_element(id: 'sc.location') }
    element.send_keys('berlin')
    element.send_keys(Selenium::WebDriver::Keys::KEYS[:tab])

    element = wait.until { driver.find_element(id: 'sc.keyword') }
    element.send_keys('ruby engineer')
    sleep(0.1)
    element.send_keys(Selenium::WebDriver::Keys::KEYS[:return])

    sleep(0.5)
    driver.save_screenshot('/site_scrapper_volume/2.png')

    driver.quit # Close browser when the task is completed
  end
end

Scrapper.new.call
