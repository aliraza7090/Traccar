# Traccar on ECS/EC2, backed by external RDS MariaDB.
# Pin a specific version rather than :latest so ECS deploys are reproducible.
# Check https://hub.docker.com/r/traccar/traccar/tags for the current tag.
FROM traccar/traccar:6.6

# Traccar 6.x reads config ONLY from conf/traccar.xml (no env-var support), so an
# entrypoint script renders that file from env vars at container start. This keeps
# the DB password out of the image (inject it via ECS Secrets Manager as DB_PASSWORD).
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Web UI / REST API. GPS device protocol ports (5000-5150) are exposed by the
# base image already; you map the ones you need in the ECS task definition.
EXPOSE 8082

ENTRYPOINT ["/entrypoint.sh"]
