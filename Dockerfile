# Test stage

# 'AS' configures Dockerfile as a multi-stage build.
#
# Multi-stage builds enable multiple 'FROM' stages.
FROM alpine AS test

# 'LABEL' directive helps identify Docker images that support the todobackend
# application.
LABEL application=todobackend

# Install basic utilities
RUN apk add --no-cache bash git

# Install build dependencies
#
# 'git' metadata can create application-version tags for Docker release image.
#
# Compile Python C extensions and stdlib, mariadbdev builds MySQL client.
RUN apk add --no-cache gcc python3-dev libffi-dev musl-dev linux-headers mariadb-dev
RUN pip3 install wheel

# Copy requirements
#
# `/src/requirements` is a path in Docker build context, not referencing a
# filesystem.
COPY /src/requirements* /build/
WORKDIR /build

# Build and install requirements
RUN pip3 wheel -r requirements_test.txt --no-cache-dir --no-input
RUN pip3 install -r requirements_test.txt -f /build --no-index --no-cache-dir

# Copy source code
COPY /src /app
WORKDIR /app

# Test entrypoint
CMD ["python3", "manage.py", "test", "--noinput", "--settings=todobackend.settings_test"]

# Release stage
FROM alpine
LABEL application=todobackend

# Install operating system dependencies
RUN apk add --no-cache python3 mariadb-client bash curl bats jq && \
    pip3 --no-cache-dir install awscli

# Create app user
#
# Set linux permissions for user and group.
RUN addgroup -g 1000 app && \
    adduser -u 1000 -G app -D app

# Copy and install application source and pre-built dependencies.
COPY --from=test --chown=app:app /build /build
COPY --from=test --chown=app:app /app /app
RUN pip3 install -r /build/requirements.txt -f /build --no-index --no-cache-dir
RUN rm -rf /build

# Create public volume
RUN mkdir /public
RUN chown app:app /public
VOLUME /public

# Entrypoint script
COPY entrypoint.sh /usr/bin/entrypoint
RUN chmod +x /usr/bin/entrypoint
ENTRYPOINT [ "/usr/bin/entrypoint" ]

# Set working directory and application user
WORKDIR /app
USER app
