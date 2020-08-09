# LINKS:
# https://medium.com/wolox/web-scraping-automation-with-selenium-and-ruby-8211e4573187
# https://tecadmin.net/setup-selenium-chromedriver-on-ubuntu/
# https://medium.com/@cesargralmeida/using-selenium-chrome-driver-and-capybara-to-automate-web-only-reports-7ffda7dfb83e

require 'selenium-webdriver'

class Scrapper

  def initialize
    @wait = Selenium::WebDriver::Wait.new(timeout: 5) # seconds

    opts = Selenium::WebDriver::Chrome::Options.new(
      args: ['--headless', '--no-sandbox', '--disable-dev-shm-usage', '--window-size=1920,1080']
    )

    @driver = Selenium::WebDriver.for(:chrome, options: opts)
  end

  def call
    # TODO: '--no-sandbox' supposedly needed just because Chrome is run under 'root' here.
    # But running with --no-sandbox is discouraged.
    # It's worth trying running this ruby script under non-root user without '--no-sandbox'
    #
    # (Or not. There's an issue with running it in Docker):
    # https://bugs.chromium.org/p/chromedriver/issues/detail?id=2473

    # # google.com  example: (Non-SPA) : --------------------------------------------------------
    #  driver.get 'https://www.google.com'

    #  el = wait.until { driver.find_elements(css: '#SIvCob a') }
    #  el.text
    #  puts el.property(:href)

    #  element = wait.until do
    #    driver.find_element(name: 'q')
    #  end

    #  # element.send_keys 'ruby'
    #  # element.submit

    #  # puts driver.page_source
    # # google.com  example: -----------------------------------------------------------------

    ## -----------------------------------------------------------------
    login

    sleep(3)

    enter_search_query

    sleep(3)

    arr = []
    iterations = 0

    loop do
      collect_vacancies_page(arr)
      break if last_page? || iterations > 30 # TODO: move this magic number '30' to a constant
      next_page_button = driver.find_elements(css: '#FooterPageNav li.next').first
      next_page_button.click

      # #<Selenium::WebDriver::Error::ElementClickInterceptedError: element click intercepted: Element <li class="next">...</li> is not clickable at point (788, 1062). Other element would receive the click: <div class="background-overlay" aria-label="Background Overlay"></div>

      sleep(10)
      iterations += 1
    end

    require 'pry'; binding.pry

    driver.quit # Close browser when the task is completed
  rescue => e
    require 'pry'; binding.pry
  end

  private

  attr_reader :wait, :driver

  def last_page?
    results_footer_text = wait.until { driver.find_element(css: '#ResultsFooter') }.text
    str = results_footer_text.split("\n").find { |x| x =~ /Page \d+ of \d+/ }

    raise 'Page number element not found' unless str

    str_arr = str.split(' ')
    str_arr[1] == str_arr[3]
  end

  def login
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
  end

  def enter_search_query
    element = wait.until { driver.find_element(id: 'sc.location') }
    element.clear

    element = wait.until { driver.find_element(id: 'sc.location') }
    element.send_keys('berlin')
    element.send_keys(Selenium::WebDriver::Keys::KEYS[:tab])

    element = wait.until { driver.find_element(id: 'sc.keyword') }
    element.send_keys('ruby engineer')
    sleep(0.1)
    element.send_keys(Selenium::WebDriver::Keys::KEYS[:return])
  end

  def collect_vacancies_page(arr)
    vacancies = wait.until { driver.find_elements(css: 'article#MainCol li') }
    vacancies.first.click
    sleep(2)

    title = wait.until { driver.find_element(id: 'HeroHeaderModule') }.text
    desc  = wait.until { driver.find_element(id: 'JobDescriptionContainer') }.text
    arr << { title: title, desc: desc  }

    # NOTE: clicking on any elements except the first one didn't work
    # (because the click was intercepted by something and it caused an exception)
    # that's why I do it just by tabbing :
    vacancies.each_with_index do |vac, i|
      break if i == 3

      driver.action.key_down(:tab).perform
      driver.action.key_up(:tab).perform

      sleep(0.1)

      driver.action.key_down(:tab).perform
      driver.action.key_up(:tab).perform

      sleep(0.1)

      driver.action.key_down(:tab).perform
      driver.action.key_up(:tab).perform

      sleep(0.1)

      driver.action.key_down(:return).perform
      driver.action.key_up(:return).perform

      sleep(10)

      title = wait.until { driver.find_element(id: 'HeroHeaderModule') }.text
      desc = wait.until { driver.find_element(id: 'JobDescriptionContainer') }.text
      arr << { title: title, desc: desc  }
    end
  end
end

Scrapper.new.call
