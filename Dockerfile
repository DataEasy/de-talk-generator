FROM rails:4.2.5.1

RUN echo "deb http://ftp.br.debian.org/debian jessie main" >> /etc/apt/sources.list

RUN apt-get update && apt-get install -y inkscape \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir /detalk
WORKDIR /detalk
ADD . /detalk
COPY ./docker/fonts/ /usr/local/share/fonts/

ENV RAILS_ENV=development

RUN bundle install
RUN bundle exec rake db:migrate
#RUN RAILS_ENV=production bundle exec rake assets:precompile --trace

CMD ["rails","s","-b","0.0.0.0"]
