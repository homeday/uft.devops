FROM python:2.7-alpine
LABEL maintainer="uft.dev.ops@hpe.com" \
      version="1.0" \
      description="Github Enterprise WebHooks (Python)"

# install all python requirements
COPY py-req.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/py-req.txt


# copy all assets to /app
WORKDIR /app
COPY . ./

EXPOSE 5000
CMD ["python", "webhooks.py"]
