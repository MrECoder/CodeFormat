# Optimized Multi-stage Dockerfile with Layer Caching
# This version separates dependencies from application code for better caching:
# Build stages: dependencies → build → runtime


# ============================================================
# Stage 1: Dependencies
# ============================================================
FROM maven:3.9-eclipse-temurin-21 AS dependencies

WORKDIR /app

# Copy only POM files first (for dependency caching)
COPY pom.xml .

# Download dependencies (cached unless POM changes)
RUN mvn dependency:go-offline \
    -Drevision=0.0.1 \
    -Dchangelist=-SNAPSHOT

# ============================================================
# Stage 2: Build
# ============================================================
FROM maven:3.9-eclipse-temurin-21 AS build

# Build arguments
ARG REVISION=0.0.1
ARG CHANGELIST=-SNAPSHOT

WORKDIR /app

# Copy dependencies from previous stage
COPY --from=dependencies /root/.m2 /root/.m2

# Copy source code
COPY pom.xml .
COPY src ./src

# Build application
RUN mvn clean package \
    -Drevision=${REVISION} \
    -Dchangelist=${CHANGELIST} \
    -DskipTests=true \
    -Dmaven.test.skip=true \
    --offline

# Extract JAR layers for better Docker layer caching
RUN java -Djarmode=layertools -jar target/*.jar extract

# ============================================================
# Stage 3: Runtime
# ============================================================
FROM eclipse-temurin:21-jre-alpine

# Metadata
ARG APP_VERSION=0.0.1-SNAPSHOT
ARG BUILD_DATE
ARG VCS_REF
ARG REVISION
ARG CHANGELIST

LABEL org.opencontainers.image.title="Application Catalogue Service"
LABEL org.opencontainers.image.version="${APP_VERSION}"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.revision="${VCS_REF}"
LABEL com.redacted.maven.revision="${REVISION}"
LABEL com.redacted.maven.changelist="${CHANGELIST}"

# Install utilities
RUN apk add --no-cache \
    curl \
    wget \
    tini

# Create app user
RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup

WORKDIR /app

# Copy Spring Boot layers (for optimal caching)
COPY --from=build /app/dependencies/ ./
COPY --from=build /app/spring-boot-loader/ ./
COPY --from=build /app/snapshot-dependencies/ ./
COPY --from=build /app/application/ ./

# Create version info
RUN printf "Application Version: %s\n" "${APP_VERSION}" > /app/version.txt && \
    printf "Build Date: %s\n" "${BUILD_DATE}" >> /app/version.txt && \
    printf "Git Commit: %s\n" "${VCS_REF}" >> /app/version.txt && \
    printf "Maven Revision: %s\n" "${REVISION}" >> /app/version.txt && \
    printf "Maven Changelist: %s\n" "${CHANGELIST}" >> /app/version.txt && \
    chmod 644 /app/version.txt

# Set ownership
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080 8081

# Health check (adjust path as needed)
HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:8080/actuator/health/liveness || exit 1

# JVM options
ENV JAVA_OPTS="-XX:+UseContainerSupport \
    -XX:MaxRAMPercentage=75.0 \
    -XX:+UseG1GC \
    -XX:+UseStringDeduplication \
    -Djava.security.egd=file:/dev/./urandom" \
    APP_OPTS=""

# Use tini for proper signal handling
ENTRYPOINT ["/sbin/tini", "--"]

CMD echo "=== Application Starting ===" && \
    cat /app/version.txt && \
    echo "===========================" && \
    java ${JAVA_OPTS} \
    org.springframework.boot.loader.launch.JarLauncher \
    ${APP_OPTS}
