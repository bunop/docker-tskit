#
# VERSION 0.1.2
# DOCKER-VERSION  25.0.3
# AUTHOR:         Paolo Cozzi <paolo.cozzi@ibba.cnr.it>
# DESCRIPTION:    A multi-stage image with tskit dependencies
# TO_BUILD:       docker build --rm -t bunop/tskit .
# TO_RUN:         docker run --rm -ti bunop/tskit bash
# TO_TAG:         docker tag bunop/tskit:latest bunop/tskit:0.1.2
#

###############################################################################
# 1st build stage

# inspired from https://bmaingret.github.io/blog/2021-11-15-Docker-and-Poetry
# Those variables are defined before the FROM scope: to use them after, recall
# ARG in build stages
ARG APP_NAME=tskit
ARG APP_PATH=/opt/$APP_NAME
ARG PYTHON_VERSION=3.11
ARG POETRY_VERSION=1.8.3

FROM python:${PYTHON_VERSION} AS python-build

# MAINTAINER is deprecated. Use LABEL instead
LABEL maintainer="paolo.cozzi@ibba.cnr.it"

# Import ARGs which I need in this build stage
# IMPORTANT!: without this redefinition, you can't use variables defined
# before the first FROM statement
ARG POETRY_VERSION
ARG APP_NAME
ARG APP_PATH

# Set some useful variables
ENV \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONFAULTHANDLER=1
ENV \
    POETRY_VERSION=${POETRY_VERSION} \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1

# Install Poetry - require $POETRY_VERSION & $POETRY_HOME environment variables
RUN curl -sSL https://install.python-poetry.org | python -
ENV PATH="$POETRY_HOME/bin:$PATH"

# CREATE APP_PATH
RUN mkdir -p ${APP_PATH}
WORKDIR ${APP_PATH}

# Need to copy all the files declared in pyproject.toml
COPY poetry.lock pyproject.toml README.md ./

# Install all dependencies (taking advantage of Docker layer caching)
RUN poetry install --no-directory --no-root

# create data dir
RUN mkdir data

###############################################################################
# 2nd build stage

FROM python:${PYTHON_VERSION} AS python-runtime

# Import ARGs which I need in this build stage
# IMPORTANT!: without this redefinition, you can't use variables defined
# before the first FROM statement
ARG APP_PATH
ARG VIRTUAL_ENV=${APP_PATH}/.venv

# Set some useful variables
ENV \
    PYTHONUNBUFFERED=1 \
    PYTHONFAULTHANDLER=1
# See https://pythonspeed.com/articles/activate-virtualenv-dockerfile/
ENV \
    VIRTUAL_ENV=${VIRTUAL_ENV} \
    PATH="${VIRTUAL_ENV}/bin:${PATH}"

# copy the application from build stage
COPY --from=python-build ${APP_PATH} ${APP_PATH}
WORKDIR ${APP_PATH}

# export data as a volume
VOLUME [ "${APP_PATH}/data" ]
