#!/bin/sh
set -e

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
while ! pg_isready -h $DATABASE_HOST -p ${DATABASE_PORT:-5432} -U $DATABASE_USER; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 2
done

echo "PostgreSQL is ready!"

# Run migrations
echo "Running database migrations..."
bin/leetcode_spaced eval "LeetcodeSpaced.Release.migrate"

# Start the Phoenix app
echo "Starting Phoenix application..."
exec "$@"