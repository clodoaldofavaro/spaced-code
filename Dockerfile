# Build stage
FROM elixir:1.18-alpine AS build

# Install build dependencies
RUN apk add --no-cache build-base git python3 curl

# Set build environment
ENV MIX_ENV=prod

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set working directory
WORKDIR /app

# Copy mix files
COPY mix.exs mix.lock ./
COPY config config

# Install mix dependencies
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

# Copy application files
COPY priv priv
COPY lib lib
COPY assets assets

# Compile assets
RUN mix assets.deploy

# Compile the application
RUN mix compile

# Build release
RUN mix release

# Runtime stage
FROM alpine:3.18 AS runtime

# Install runtime dependencies
RUN apk add --no-cache libstdc++ openssl ncurses-libs postgresql-client

ENV MIX_ENV=prod
ENV LANG=C.UTF-8

# Create app user
RUN addgroup -g 1000 app && \
    adduser -u 1000 -G app -s /bin/sh -D app

WORKDIR /app

# Copy release from build stage
COPY --from=build --chown=app:app /app/_build/prod/rel/leetcode_spaced ./

# Copy entrypoint script
COPY --chown=app:app docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

USER app

# Expose port
EXPOSE 4000

# Set entrypoint
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["bin/leetcode_spaced", "start"]