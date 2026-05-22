╔═══════════════════════════════════════════════════════════╗

║         CI-FRIENDLY VERSIONS QUICK REFERENCE              ║

╚═══════════════════════════════════════════════════════════╝

POM STRUCTURE
─────────────────────────────────────────────────────────────

<version>${revision}${changelist}</version>

<properties>
  <revision>0.0.1</revision>
  <changelist>-SNAPSHOT</changelist>
</properties>

COMMON COMMANDS
─────────────────────────────────────────────────────────────

Local Build (Default):
  $ mvn clean install
  → Produces: 0.0.1-SNAPSHOT

Test Feature Version:
  $ mvn clean install \
      -Drevision=0.0.1 \
      -Dchangelist=-SNAPSHOT-test
  → Produces: 0.0.1-SNAPSHOT-test

Deploy to Nexus:
  $ mvn clean deploy \
      -Drevision=0.0.1 \
      -Dchangelist=-SNAPSHOT

VERSION PATTERNS
─────────────────────────────────────────────────────────────

Main Branch:          0.0.1-SNAPSHOT
Feature Branch:       0.0.1-SNAPSHOT-jsmith-feature-auth
Merge Request:        0.0.1-SNAPSHOT-MR123
Release Tag:          0.0.2

TROUBLESHOOTING
─────────────────────────────────────────────────────────────

Issue: Parent POM not found
Fix:   cd parent-pom && mvn install

Issue: ${revision} not resolved
Fix:   Check flatten-maven-plugin in POM

Issue: Build fails in CI
Fix:   Check GitLab CI logs for calculate-version

RESOURCES
─────────────────────────────────────────────────────────────

Docs:    [wiki link]
Slack:   #engineering-maven-migration
Support: [email]

╔═══════════════════════════════════════════════════════════╗

║  NO MORE MANUAL VERSION EDITING! LET CI/CD HANDLE IT!    ║

╚═══════════════════════════════════════════════════════════╝
