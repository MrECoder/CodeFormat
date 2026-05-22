Provide this to developers for self-paced learning:
markdown# CI-Friendly Versions Hands-On Workshop

## Prerequisites
- Git access to parent-pom repository
- Maven 3.9+ installed
- Access to Nexus repository
- GitLab account with CI/CD access

## Exercise 1: Understanding the Changes (15 minutes)

### Step 1: Clone parent-pom repository
```bash
git clone https://git.electra.lan/parent-pom.git
cd parent-pom
git checkout main
```

### Step 2: Examine BOM POM
```bash
cat bom/pom.xml | grep -A 5 ""
```

**Expected Output:**
```xml

    0.0.1
    -SNAPSHOT
    ...

```

### Step 3: Build parent POMs locally
```bash
cd aggregator
mvn clean install
```

**Verify:** Check `~/.m2/repository/redacted/group/id/redacted-bom/0.0.1-SNAPSHOT/`

### Step 4: Test version override
```bash
mvn clean install -Drevision=0.0.1 -Dchangelist=-SNAPSHOT-workshop
```

**Verify:** Artifact should be `0.0.1-SNAPSHOT-workshop`

## Exercise 2: Feature Branch Simulation (20 minutes)

### Step 1: Create a test feature branch
```bash
cd common-java-components
git checkout -b feature/workshop-test
```

### Step 2: Make a trivial change
```bash
echo "// Workshop test" >> src/main/java/SomeClass.java
git add .
git commit -m "Workshop: test CI-friendly versions"
```

### Step 3: Push and watch CI
```bash
git push origin feature/workshop-test
```

### Step 4: Monitor GitLab CI
- Open GitLab pipeline
- Watch calculate-version stage
- Note the version calculated
- Check build artifacts

### Step 5: Find your artifact in Nexus
- Navigate to Nexus
- Search for `common-java-components`
- Find your versioned artifact
- Examine the POM

## Exercise 3: Local Development (15 minutes)

### Step 1: Build with default version
```bash
cd common-java-components
mvn clean package
```

**Expected:** `0.0.1-SNAPSHOT`

### Step 2: Simulate feature branch build
```bash
mvn clean package \
  -Drevision=0.0.1 \
  -Dchangelist=-SNAPSHOT-$(whoami)-workshop
```

### Step 3: Examine the built JAR
```bash
unzip -p target/*.jar META-INF/MANIFEST.MF
```

**Look for:** Implementation-Version

### Step 4: Check flattened POM
```bash
cat .flattened-pom.xml | grep ""
```

**Verify:** No ${revision} or ${changelist} - should be resolved

## Exercise 4: Debugging (10 minutes)

### Scenario: Dependency resolution fails

**Simulate:**
```bash
# Temporarily remove parent from local repo
rm -rf ~/.m2/repository/redacted/group/id/redacted-parent

# Try to build
mvn clean install
```

**Expected:** Error - parent POM not found

**Fix:**
```bash
cd parent-pom/parent
mvn install -Drevision=0.0.1 -Dchangelist=-SNAPSHOT
```

## Exercise 5: Docker Build (15 minutes)

### Step 1: Update Dockerfile
```bash
cd application-catalogue-service
# Review Dockerfile build args
```

### Step 2: Build image locally
```bash
docker build \
  --build-arg REVISION=0.0.1 \
  --build-arg CHANGELIST=-SNAPSHOT-workshop \
  --build-arg APP_VERSION=0.0.1-SNAPSHOT-workshop \
  --tag catalogue:workshop \
  .
```

### Step 3: Inspect image
```bash
docker inspect catalogue:workshop | jq '.[0].Config.Labels'
```

### Step 4: Run and verify
```bash
docker run catalogue:workshop cat /app/version.txt
```

## Completion Checklist

- [ ] Successfully built parent POMs locally
- [ ] Created and pushed a feature branch
- [ ] Watched GitLab CI calculate version
- [ ] Found artifacts in Nexus
- [ ] Built with custom version locally
- [ ] Examined flattened POM
- [ ] Built Docker image with version
- [ ] Understood troubleshooting steps

## Quiz (Test Your Knowledge)

1. What are the two CI-friendly properties?
2. Where does version calculation happen?
3. What version does `mvn clean install` produce locally?
4. How do you find your feature branch artifacts in Nexus?
5. What plugin resolves ${revision} in deployed POMs?
