FROM ruby:3.4-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libyaml-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and install dependencies
COPY Gemfile* ./
RUN bundle config set --local without 'development test' && \
    bundle install || bundle install

# Copy application files
COPY . .

# Create directories for data persistence
RUN mkdir -p /app/public /app/data

# Set environment variables
ENV REUDY_DIR=/app/lib/reudy
ENV OUT_KCODE=UTF-8

# Default command (can be overridden)
CMD ["ruby", "stdio_reudy.rb"]

