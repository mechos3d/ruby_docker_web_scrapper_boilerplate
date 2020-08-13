# LINKS:
# https://medium.com/wolox/web-scraping-automation-with-selenium-and-ruby-8211e4573187
# https://tecadmin.net/setup-selenium-chromedriver-on-ubuntu/
# https://medium.com/@cesargralmeida/using-selenium-chrome-driver-and-capybara-to-automate-web-only-reports-7ffda7dfb83e

require 'selenium-webdriver'
require 'fileutils'

# TODO: can move 'driver' and 'wait' to a Singleton
# TODO: rewrite 'with_retry_if_stale' without using the 'callable' argument - with a simple block

# class A
#   def call(*args, &block)
#     @count ||= 0
#     @count += 1
#
#     if @count > 3
#       block.call
#     else
#       call(&block)
#     end
#   end
# end
#
# A.new.call do
#   puts '111'
# end

OUT_DIR = begin
  dirname = "#{ENV.fetch('query')}__#{ENV.fetch('location')}".tr(' ', '_')
  dirname = File.join('.', 'site_scrapper_volume', dirname)
  FileUtils.mkdir_p(dirname)
  dirname
end

class Utils

  def initialize(driver, wait)
    @driver = driver
    @wait = wait
  end

  def with_retry_if_stale(callable, counter = 0)
    raise 'Too many Stale-retry iterations' if counter > 10
    callable.call

  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    with_retry_if_stale(callable, counter + 1)
  end

  def kill_intrusive_modal
    # NOTE: the modal that suggests to activate email subscription for these jobs
    #       seems to appear out of the blue unexpectedly.
    yield
  rescue Selenium::WebDriver::Error::ElementClickInterceptedError
    close_modal
    yield
  end

  def close_modal
    close_modal_button =
      @wait.until { @driver.find_elements(css: '#JAModal svg.modal_closeIcon-svg') }.first

    close_modal_button.click
  end
end

# TODO: refactor this:
class VacanciesListCollector
  def initialize(driver, wait, arr, index, counter)
    @driver   = driver
    @wait     = wait
    @arr      = arr
    @index    = index
    @counter  = counter
  end

  def call
    Utils.new(driver, wait).with_retry_if_stale(
      lambda do
        Utils.new(driver, wait).kill_intrusive_modal do
          vacs = wait.until { driver.find_elements(css: 'article#MainCol div.jobContainer') }
          vacs[index].click
        end
      end
    )

    sleep(8)

    title = Utils.new(driver, wait).with_retry_if_stale(
      lambda do
        wait.until { driver.find_element(id: 'HeroHeaderModule') }.text
      end
    )

    desc = Utils.new(driver, wait).with_retry_if_stale(
      lambda do
        wait.until { driver.find_element(id: 'JobDescriptionContainer') }.text
      end
    )
    arr << { title: title, desc: desc  }

    filename = File.join(OUT_DIR, counter[:current_vacancy].to_s)

    File.open(filename, 'w') do |f|
      f.puts("title: \n#{title}\ndesc: \n#{desc}")
    end
  end

  private

  attr_reader :driver, :wait, :arr, :index, :counter

end

# TODO: show total number of found jobs and then show the current job total-number (not just page_index + index)
#  '#MainColSummary' ->  p.jobsCount

class Scrapper

  def initialize
    @wait = Selenium::WebDriver::Wait.new(timeout: 15) # seconds

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

    sleep(10)

    enter_search_query

    sleep(10)

    arr = []
    iterations = 0
    counter = { current_vacancy: 0 }

    loop do
      collect_vacancies_page(arr, counter)
      break if last_page? || iterations > 30 # TODO: move this magic number '30' to a constant
      next_page_button = driver.find_elements(css: '#FooterPageNav li.next').first

      # driver.save_screenshot('/site_scrapper_volume/foo.png')
      # require 'pry'; binding.pry

      # TODO: тут проблема с модалкой: JAModal
      # кажется она рандомно появляется. надо найти у нее кнопку:
      # и поэтому же видимо была проблема с кликаньем на элементы списка вакансий (можно к этому вернуться и убрать
      # убогий код с кучей табов)
      #
      # svg с классом 'SVGInline-svg modal_closeIcon-svg' и нажать на нее

      # next_page_button.click
      Utils.new(driver, wait).kill_intrusive_modal { next_page_button.click }

      # TODO: obviously it's better to find another way to guarantee that new content is already loaded:
      #       one way is to find some element, and than to check it's contents every 0.1 seconds.
      #       if the content did change - this means that Ajax call is finished ?.
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
    element.send_keys(ENV.fetch('location'))
    element.send_keys(Selenium::WebDriver::Keys::KEYS[:tab])

    element = wait.until { driver.find_element(id: 'sc.keyword') }
    element.send_keys(ENV.fetch('query'))
    sleep(0.1)
    element.send_keys(Selenium::WebDriver::Keys::KEYS[:return])
  end

  def collect_vacancies_page(arr, counter)
    vacancies_count = wait.until { driver.find_elements(css: 'article#MainCol div.jobContainer') }.size

    vacancies_count.times do |index|
      puts "vacancy: #{counter[:current_vacancy]}"

      current_index = counter[:current_vacancy]
      unless current_index < ENV.fetch('offset', 0).to_i
        VacanciesListCollector.new(driver, wait, arr, index, counter).call
      end
      counter[:current_vacancy] += 1
    end
  end
end

Scrapper.new.call

# driver.save_screenshot("/site_scrapper_volume/#{page_index}__#{index}.png")
