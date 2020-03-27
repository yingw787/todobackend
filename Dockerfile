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
