# Dockerfile

FROM ruby:3.1.2

WORKDIR /app
COPY . /app
RUN bundle install

ENV JWT_ISSUER = 'DSSD'
ENV JWT_SECRET = 'DSSD-Secret'

EXPOSE 4567

CMD ["bundle", "exec", "thin", "start", "-p", "4567"]