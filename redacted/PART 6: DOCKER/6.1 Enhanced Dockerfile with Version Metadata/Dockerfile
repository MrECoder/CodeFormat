# Multi-stage Dockerfile for Spring Boot Microservices
# Supports CI-friendly Maven versions

# ============================================================
# Stage 1: Build (optional - if building in Docker)
# ============================================================
FROM maven:3.9-eclipse-temurin-21 AS build

# Build arguments for versioning
ARG REVISION=0.0.1
ARG CHANGELIST=-SNAPSHOT

WORKDIR /app

# Copy POM files
COPY pom.xml .
COPY src ./src

# Build the application
RUN mvn clean package \
    -Drevision=${REVISION} \
    -Dchangelist=${CHANGELIST} \
    -DskipTests=true

# ============================================================
# Stage 2: Runtime
# ============================================================
FROM eclipse-temurin:21-jre-alpine

# Metadata labels (OCI standard)
ARG APP_VERSION=unknown
ARG BUILD_DATE=unknown
ARG VCS_REF=unknown
ARG REVISION=0.0.1
ARG CHANGELIST=-SNAPSHOT

LABEL org.opencontainers.image.title="Application Catalogue Service"
LABEL org.opencontainers.image.description="Application Registration service and broadcast notifier"
LABEL org.opencontainers.image.version="${APP_VERSION}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.revision="${VCS_REF}"
LABEL org.opencontainers.image.vendor="redacted.group.id"
LABEL com.redacted.maven.revision="${REVISION}"
LABEL com.redacted.maven.changelist="${CHANGELIST}"

# Create app user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy JAR from build stage OR from local target directory
# If using GitLab CI with maven build, copy from target/
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} app.jar

# Create version info file
RUN echo "Application Version: ${APP_VERSION}" > /app/version.txt && \
    echo "Build Date: ${BUILD_DATE}" >> /app/version.txt && \
    echo "Git Commit: ${VCS_REF}" >> /app/version.txt && \
    echo "Maven Revision: ${REVISION}" >> /app/version.txt && \
    echo "Maven Changelist: ${CHANGELIST}" >> /app/version.txt

# Set ownership
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose application port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# Environment variables
ENV JAVA_OPTS="" \
    APP_OPTS=""

# Display version on startup
ENTRYPOINT echo "=== Starting Application ===" && \
           cat /app/version.txt && \
           echo "===========================" && \
           exec java ${JAVA_OPTS} \
           -jar /app/app.jar \
           ${APP_OPTS}
