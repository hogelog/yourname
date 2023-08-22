FROM public.ecr.aws/docker/library/ruby:3.2-slim AS build

RUN apt-get update && apt-get install -y --no-install-recommends build-essential

COPY Gemfile Gemfile.lock /src/
WORKDIR /src
RUN bundle install

FROM public.ecr.aws/docker/library/ruby:3.2-slim

WORKDIR /app

COPY --from=build /usr/local/bundle/ /usr/local/bundle/

COPY . /app/

CMD ["bundle", "exec", "rackup", "-E", "production", "-p", "8080"]
