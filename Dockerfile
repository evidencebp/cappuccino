# syntax=docker/dockerfile:1

ARG DEBIAN_VERSION=bookworm
ARG PYTHON_VERSION=3.13

## Base
FROM python:${PYTHON_VERSION}-slim-${DEBIAN_VERSION} AS python-base

ARG META_VERSION
ARG META_VERSION_HASH
ARG META_SOURCE

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_CREATE=false \
    POETRY_NO_INTERACTION=1 \
    # Latest
    POETRY_VERSION="" \
    VIRTUAL_ENV="/venv" \
    META_VERSION="${META_VERSION}" \
    META_VERSION_HASH="${META_VERSION_HASH}" \
    META_SOURCE="${META_SOURCE}"

ENV PATH="${POETRY_HOME}/bin:${VIRTUAL_ENV}/bin:${PATH}" \
    PYTHONPATH="/app:${PYTHONPATH}"

RUN python -m venv "${VIRTUAL_ENV}"

WORKDIR /app


## Python builder
FROM python-base AS python-builder-base

RUN --mount=type=cache,target=/var/cache/apt,sharing=private \
    apt-get update && \
    apt-get install --no-install-recommends -y \
    curl \
    build-essential \
    libpq-dev \
    && apt-get autoclean && rm -rf /var/lib/apt/lists/*

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN --mount=type=cache,target=/root/.cache \
    curl -sSL https://install.python-poetry.org | python3 -

COPY poetry.lock pyproject.toml ./
RUN --mount=type=cache,target=/root/.cache \
    poetry install --only main,docker


## Production image
FROM python-base AS production

RUN --mount=type=cache,target=/var/cache/apt,sharing=private \
    apt-get update && \
    apt-get install --no-install-recommends -y \
    libpq5 \
    && apt-get autoclean && rm -rf /var/lib/apt/lists/*

COPY --from=python-builder-base ${VIRTUAL_ENV} ${VIRTUAL_ENV}
COPY docker/rootfs /
COPY cappuccino ./cappuccino
COPY alembic ./alembic
COPY alembic.ini ./

ENV SETTINGS_FILE="/tmp/config.ini" \
    SETTINGS_SOURCE_FILE="/config/config.ini"

VOLUME ["/config"]
EXPOSE 1337

ENTRYPOINT ["/docker-entrypoint.sh"]
