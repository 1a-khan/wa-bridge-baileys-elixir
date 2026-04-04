FROM elixir:1.17

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates \
  && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && rm -rf /var/lib/apt/lists/*

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
COPY lib ./lib
COPY node ./node

RUN mix local.hex --force \
  && mix local.rebar --force \
  && mix deps.get \
  && mix compile

RUN cd node && npm install

EXPOSE 4001

CMD ["mix", "run", "--no-halt"]
