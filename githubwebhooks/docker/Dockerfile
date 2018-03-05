FROM python:2.7-alpine
LABEL maintainer="uft.dev.ops@hpe.com"

WORKDIR /app

ARG http_proxy=http://web-proxy.il.hpecorp.net:8080
ARG https_proxy=$http_proxy

COPY requirements.txt /app
RUN pip install --proxy=$http_proxy -r requirements.txt

COPY . /app

EXPOSE 5000
CMD ["python", "webhooks.py"]
