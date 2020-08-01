FROM ubuntu:18.04

# taken from here: https://tecadmin.net/setup-selenium-chromedriver-on-ubuntu/
RUN apt-get update
RUN apt-get install -y unzip xvfb libxi6 libgconf-2-4 curl gnupg2
RUN apt-get install -y default-jdk

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

# NOTE: on 02-08-2020 it installed ruby-2.5
RUN apt-get install -y ruby-dev
RUN gem install bundler

COPY Gemfile Gemfile.lock /
RUN bundle install

# RUN wget https://selenium-release.storage.googleapis.com/3.141/selenium-server-standalone-3.141.59.jar

# RUN wget http://www.java2s.com/Code/JarDownload/testng/testng-6.8.7.jar.zip
# RUN unzip testng-6.8.7.jar.zip
