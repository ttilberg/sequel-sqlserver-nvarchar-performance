FROM ruby:2.6

RUN apt-get update && apt-get install -qy freetds-dev

RUN gem update --system
RUN gem install bundler

WORKDIR /app

COPY Gemfile* ./

RUN bundle install

COPY . ./

CMD rake -T
