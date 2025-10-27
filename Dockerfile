FROM elixir:1.19.1-alpine


RUN apk update && \
    apk --no-cache --update add \
      make \
      g++ \
      git \
      wget \
      curl \
      npm \
      inotify-tools && \
    rm -rf /var/cache/apk/*

ARG INSTANCE
ENV MIX_ENV $INSTANCE
ENV NODE_ENV production

# Ensure latest versions of Hex/Rebar are installed on build
RUN mix do local.hex --force, local.rebar --force
    # mix archive.install --force hex phx_new 1.5.9


RUN mkdir /app
WORKDIR /app

# Install deps
COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get && \
    mix deps.compile

# Install assets
COPY assets assets
RUN yarn --cwd assets install

# Compile and digest the app
COPY priv priv
COPY lib lib
RUN mix compile && \
    mix assets.deploy

CMD mix phx.server
