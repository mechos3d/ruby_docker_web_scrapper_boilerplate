FROM ubuntu:18.04

# most stuff is taken from here: https://tecadmin.net/setup-selenium-chromedriver-on-ubuntu/
RUN apt-get update
RUN apt-get install -y unzip xvfb libxi6 libgconf-2-4 curl gnupg2 default-jdk

# NOTE: on 02-08-2020 ruby-dev installed ruby-2.5
# NOTE: build-essential patch zlib1g-dev liblzma-dev are needed for nokogiri installation:
#       https://nokogiri.org/tutorials/installing_nokogiri.html
RUN apt-get install -y build-essential patch ruby-dev zlib1g-dev liblzma-dev vim

RUN curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add
RUN echo "deb [arch=amd64]  http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list
RUN apt-get -y update

# NOTE: this installed Chrome version 84.0.4147.105-1 on 02-08-2020:
RUN apt-get -y install google-chrome-stable

RUN wget https://chromedriver.storage.googleapis.com/84.0.4147.30/chromedriver_linux64.zip
RUN unzip chromedriver_linux64.zip
RUN mv chromedriver /usr/bin/chromedriver
RUN chown root:root /usr/bin/chromedriver
RUN chmod +x /usr/bin/chromedriver

RUN gem install bundler

COPY Gemfile /
RUN bundle install

COPY scrapper.rb /

CMD ["bundle", "exec", "ruby", "scrapper.rb"]
