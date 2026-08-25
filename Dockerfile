# Traccar on ECS/EC2, backed by external RDS MariaDB.
# Pin a specific version rather than :latest so ECS deploys are reproducible.
# Check https://hub.docker.com/r/traccar/traccar/tags for the current tag.
FROM traccar/traccar:6.6

# Bake in our config. This overrides the default conf/traccar.xml.
# Secrets (DB user/password/url) are NOT baked in here — they are injected
# at runtime via environment variables (see traccar.xml + ECS task def).
COPY traccar.xml /opt/traccar/conf/traccar.xml

# Web UI / REST API. GPS device protocol ports (5000-5150) are exposed by the
# base image already; you map the ones you need in the ECS task definition.
EXPOSE 8082
