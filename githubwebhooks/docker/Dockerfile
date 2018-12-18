FROM python:2.7-alpine
LABEL maintainer="uft.devops.cn@microfocus.com" \
      version="1.1" \
      description="GitHub Enterprise WebHooks (Python)"

# Install self-signed root CA
ADD certs/* /tmp/certs/
RUN apk add --no-cache ca-certificates && \
    mkdir -p /usr/local/share/ca-certificates && \
    cp -R /tmp/certs/* /usr/local/share/ca-certificates/ && \
    update-ca-certificates

# install all python requirements
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt


# copy all assets to /app
WORKDIR /app
COPY . ./

EXPOSE 5000
CMD ["python", "webhooks.py"]
