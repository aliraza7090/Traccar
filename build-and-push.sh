#!/bin/sh
# Build the Traccar image on a Mac M1 (arm64) and push a MULTI-ARCH image to ECR
# so the SAME tag runs on Amazon Linux 2 x86_64 EC2 *and* locally on the M1.
#
# Why multi-arch: an image built natively on M1 is arm64 and will NOT run on
# x86_64 EC2 (exec format error). buildx cross-builds amd64 too and pushes both
# under one manifest; ECS auto-selects the arch matching the EC2 instance.
#
# Usage:
#   AWS_ACCOUNT_ID=664418981336 ./build-and-push.sh
# Optional overrides: AWS_REGION (default ca-central-1), REPO (traccar), TAG (6.6)
set -e

AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:?set AWS_ACCOUNT_ID}"
AWS_REGION="${AWS_REGION:-ca-central-1}"
REPO="${REPO:-traccar}"
TAG="${TAG:-6.6}"
REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
REPO_URI="$REGISTRY/$REPO"

# Ensure the ECR repo exists.
aws ecr describe-repositories --repository-names "$REPO" --region "$AWS_REGION" >/dev/null 2>&1 \
  || aws ecr create-repository --repository-name "$REPO" --region "$AWS_REGION" >/dev/null

# Log Docker into ECR.
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"

# Use a buildx builder capable of multi-platform output.
docker buildx create --use --name traccar-builder >/dev/null 2>&1 \
  || docker buildx use traccar-builder

# Cross-build both arches and push directly to ECR as one multi-arch manifest.
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t "$REPO_URI:$TAG" \
  -t "$REPO_URI:latest" \
  --push \
  .

echo "Pushed $REPO_URI:$TAG and :latest  (linux/amd64 + linux/arm64)"
