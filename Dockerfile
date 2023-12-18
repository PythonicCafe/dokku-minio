FROM minio/minio:latest AS minio-bin

FROM debian

RUN addgroup --gid ${GID:-1000} minio \
  && adduser --gid ${GID:-1000} --uid ${UID:-1000} --home=/app minio \
  && chown -R minio:minio /app

COPY --from=minio-bin /usr/bin/minio /app/minio

EXPOSE 9000
EXPOSE 9001

VOLUME ["/data"]
