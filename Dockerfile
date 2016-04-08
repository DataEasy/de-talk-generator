FROM rails:4.2.5.1

WORKDIR /detalk
ADD . /detalk
COPY ./docker/fonts/ /usr/local/share/fonts/

VOLUME /detalk/config /detalk/public/images

ENV RAILS_ENV=production

RUN echo "deb http://ftp.br.debian.org/debian jessie main" >> /etc/apt/sources.list \
    && apt-get update && apt-get install -y vim inkscape \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && mkdir -p /detalk/tmp/pids/ \
    && bundle install \
    && bundle exec rake assets:precompile --trace

CMD ["rails","s","-b","0.0.0.0"]
