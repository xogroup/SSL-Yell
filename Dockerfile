FROM ruby:2.4.0

WORKDIR /usr/app/

COPY . /usr/app/

RUN cd /usr/app; \
    gem install bundler; \
    bundle install;

ENTRYPOINT [ "/usr/app/bin/ssl_yell.rb" ]