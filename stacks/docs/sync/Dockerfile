FROM python:3.13-alpine3.21
LABEL org.opencontainers.image.title="docs-sync"
LABEL org.opencontainers.image.description="Gitea webhook → git pull sidecar for docstore"

RUN apk add --no-cache git

WORKDIR /app
COPY sync.py .

EXPOSE 8080

CMD ["python3", "-u", "sync.py"]
