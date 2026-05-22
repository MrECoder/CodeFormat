Slide 1: Title
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
         MAVEN CI-FRIENDLY VERSIONS
    Streamlining Feature Branch Development
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                    [Your Company]
               Engineering Team Training
                  [Today's Date]
Speaker Notes:

Welcome everyone
This training covers a major improvement to our development workflow
Will eliminate the manual POM editing we've all dealt with
Session will be ~30 minutes with Q&A


Slide 2: The Problem We're Solving
THE CURRENT PAIN POINTS

❌ Manual Version Editing
   • Edit 8+ POM files for every feature branch
   • Version format: 0.0.1-user.nameX
   
❌ Pre-Merge Cleanup
   • Remember to revert all version changes
   • Error-prone manual commits
   • Delays in code reviews
   
❌ Merge Conflicts
   • Version conflicts between feature branches
   • Time wasted resolving POM conflicts
   
❌ Lost Time
   • ~15-30 minutes per feature branch setup
   • ~10-20 minutes per merge preparation
Speaker Notes:

Raise hands: Who has forgotten to revert versions before merge?
Who has had version conflicts during merge?
This pain is universal across the team
Let's quantify: 5 features/month × 30 min = 2.5 hours lost per developer


Slide 3: The Solution - CI-Friendly Versions
MAVEN CI-FRIENDLY VERSIONS

✓ Version Properties in POMs
   <version>${revision}${changelist}</version>
   
✓ Properties Default to SNAPSHOT
   <revision>0.0.1</revision>
   <changelist>-SNAPSHOT</changelist>
   
✓ GitLab CI Overrides at Build Time
   mvn install -Drevision=0.0.1 \
               -Dchangelist=-SNAPSHOT-jsmith-feature-auth
   
✓ Zero POM Edits Required
   Source control POMs never change!
Speaker Notes:

Maven 3.5+ feature, we're finally adopting it
Properties act as placeholders
CI/CD injects actual values at build time
POMs in Git always look the same


Slide 4: How It Works - Version Calculation
VERSION CALCULATION LOGIC

Context              │ Version Example
─────────────────────┼─────────────────────────────────────
Main Branch          │ 0.0.1-SNAPSHOT
Feature Branch       │ 0.0.1-SNAPSHOT-jsmith-feature-auth
Merge Request        │ 0.0.1-SNAPSHOT-MR123
Tagged Release       │ 0.0.2

═══════════════════════════════════════════════════════════

Automatic, based on:
  • Git branch name
  • Your GitLab username  
  • Merge request number
  • Git tags
Speaker Notes:

Algorithm is in GitLab CI pipeline
You don't need to think about it
Version tells us who built it and why
Easy to find your artifacts in Nexus


Slide 5: Before vs After Workflow
BEFORE: Manual Version Management

1. Create feature branch
2. ❌ Edit parent POM version → 0.0.1-jsmith
3. ❌ Edit BOM properties → all components
4. ❌ Edit all 5 component POMs
5. ❌ Edit .gitlab-ci.yml
6. Code your feature
7. ❌ Revert ALL version changes
8. ❌ Commit reversions
9. Create MR

───────────────────────────────────────────────────────────

AFTER: CI-Friendly Versions

1. Create feature branch
2. Code your feature
3. Create MR

Done! 🎉
Speaker Notes:

This is the biggest win
Steps 2-5 and 7-8 completely eliminated
You can focus on actual feature development
No more "oops I forgot to revert versions"


Slide 6: What Changed in the POMs
POM FILE CHANGES

OLD:
  <version>0.0.1-user.nameX</version>

NEW:
  <version>${revision}${changelist}</version>
  
  <properties>
    <revision>0.0.1</revision>
    <changelist>-SNAPSHOT</changelist>
  </properties>

═══════════════════════════════════════════════════════════

CRITICAL: These properties NEVER change in Git!
         Values injected by CI/CD at build time
Speaker Notes:

Simple property substitution
The defaults (-SNAPSHOT) are for local development
CI overrides with feature branch specific values
You commit these exact properties


Slide 7: Local Development
LOCAL DEVELOPMENT WORKFLOW

Build Normally:
  $ mvn clean install
  
  Result: 0.0.1-SNAPSHOT
  
───────────────────────────────────────────────────────────

Test Feature Branch Versioning:
  $ mvn clean install \
      -Drevision=0.0.1 \
      -Dchangelist=-SNAPSHOT-jsmith-test
  
  Result: 0.0.1-SNAPSHOT-jsmith-test
  
───────────────────────────────────────────────────────────

Everything works exactly as before!
No changes to your local workflow!
Speaker Notes:

Default build just works
Optional: test what CI will do
No new tools to install
VS Code, IntelliJ work normally


Slide 8: CI/CD Pipeline Changes
GITLAB CI/CD PIPELINE

New Stage: calculate-version (automatic)
  ├─ Detects branch context
  ├─ Calculates version suffix
  └─ Exports environment variables

Build Stage (updated)
  ├─ Uses calculated version
  └─ mvn install -Drevision=X -Dchangelist=Y

Deploy Stage (updated)
  ├─ Artifacts tagged with full version
  └─ Docker images labeled correctly
  
═══════════════════════════════════════════════════════════

YOU DON'T EDIT .gitlab-ci.yml ANYMORE!
Speaker Notes:

Pipeline handles everything
Calculate-version runs first
Downstream jobs use the calculated version
One template, all projects


Slide 9: Finding Your Artifacts
NEXUS ARTIFACT LOCATIONS

Old Way:
  redacted/common-java-components/0.0.1-jsmith/

New Way:
  redacted/common-java-components/
    ├─ 0.0.1-SNAPSHOT/                    (main)
    ├─ 0.0.1-SNAPSHOT-jsmith-feature-auth/ (your branch)
    └─ 0.0.1-SNAPSHOT-MR123/               (merge request)

═══════════════════════════════════════════════════════════

Search by:
  • Your username
  • Branch name
  • MR number
Speaker Notes:

Easier to find your specific builds
No collision between developers
Old user.nameX pattern is gone
More descriptive, self-documenting


Slide 10: Docker Images
DOCKER IMAGE TAGGING

Old Way:
  registry.electra.lan/catalogue-service:latest
  registry.electra.lan/catalogue-service:0.0.1-jsmith

New Way:
  registry.electra.lan/catalogue-service:
    ├─ latest                                    (main)
    ├─ 0.0.1-SNAPSHOT                           (main)
    ├─ 0.0.1-SNAPSHOT-jsmith-feature-auth-a1b2c3 (feature)
    └─ 0.0.2                                    (release)

═══════════════════════════════════════════════════════════

Version + Git SHA = Unique, Traceable
Speaker Notes:

Images now include full version
Git commit SHA added for uniqueness
Can trace back to exact commit
Improved debugging capability


Slide 11: Migration Timeline
MIGRATION SCHEDULE

Week 1: Parent POM Repository
  ✓ BOM, Parent, Aggregator, Code-Style
  ✓ Deployed to Nexus
  
Week 2: Shared Components  
  ⊙ common-java-components
  ⊙ common-rabbitmq-components
  ⊙ common-notification-service
  
Week 3: Microservices
  ⊙ application-catalogue-service
  ⊙ application-instance-access-service
  
Week 4: Cleanup & Stabilization
  ⊙ Remove old versioned artifacts
  ⊙ Update documentation
Speaker Notes:

Phased rollout, not big bang
Parent POMs done first (foundation)
Components depend on parent
Microservices last
We're currently in Week X


Slide 12: What You Need to Do
ACTION ITEMS FOR DEVELOPERS

1️⃣ READ THE MIGRATION GUIDE
   [Link to internal docs]

2️⃣ UPDATE YOUR MAVEN SETTINGS
   ~/.m2/settings.xml
   (See guide Section 3.2)

3️⃣ REBASE ACTIVE FEATURE BRANCHES
   After your component is migrated:
   $ git rebase origin/main

4️⃣ TEST LOCAL BUILD
   $ mvn clean install
   Should produce: 0.0.1-SNAPSHOT

5️⃣ WATCH FOR SLACK ANNOUNCEMENTS
   #engineering-maven-migration
Speaker Notes:

These are your homework items
Settings.xml update is one-time
Rebase when your component is done
Test to verify everything works
Ask questions in Slack


Slide 13: New Feature Branch Workflow
CREATING A NEW FEATURE BRANCH (After Migration)

1. Checkout main
   $ git checkout main
   $ git pull

2. Create feature branch
   $ git checkout -b feature/my-awesome-feature

3. Code your feature
   [Your brilliant code here]

4. Commit and push
   $ git add .
   $ git commit -m "Add awesome feature"
   $ git push origin feature/my-awesome-feature

5. Create Merge Request
   GitLab → New MR

THAT'S IT! No POM editing! 🚀
Speaker Notes:

This is the new normal
Notice what's missing: POM edits!
CI automatically versions your build
Focus on code, not build infrastructure


Slide 14: Troubleshooting
COMMON ISSUES & SOLUTIONS

Problem: "Could not resolve dependencies"
Solution: Parent POM not deployed yet
  → Wait for parent-pom migration
  → Or deploy locally: mvn install in parent-pom

Problem: "Unresolved property: ${revision}"
Solution: Missing flatten plugin
  → Check POM has flatten-maven-plugin

Problem: Build works locally, fails in CI
Solution: Settings.xml differences
  → Ensure CI settings match local
  
Problem: Old version artifacts conflict
Solution: Clear local Maven cache
  → rm -rf ~/.m2/repository/redacted/group/id
Speaker Notes:

Don't panic if something breaks
Most issues are transitional
Check Slack channel first
Reach out to [Team Lead] if stuck
We have rollback plan if needed


Slide 15: Benefits Summary
WHAT WE GAIN

⚡ Speed
   • No manual POM editing
   • Faster feature branch setup
   • Quicker merges

🎯 Accuracy  
   • No version revert mistakes
   • Consistent versioning
   • Fewer merge conflicts

🔍 Traceability
   • Version includes username
   • Branch name in version
   • Git SHA in Docker images

📦 Better Artifacts
   • JARs preserved in Nexus
   • Easier debugging
   • Proper SNAPSHOT semantics
Speaker Notes:

Time saved: ~2-3 hours/developer/month
Reduced merge request review time
Better audit trail
Professional build process


Slide 16: FAQs
FREQUENTLY ASKED QUESTIONS

Q: Do I need to update my IDE?
A: No, everything works as before

Q: What about my existing feature branches?
A: Rebase onto main after migration

Q: Can I still build locally?
A: Yes! mvn clean install works normally

Q: What if I need a specific version?
A: mvn install -Drevision=X -Dchangelist=Y

Q: How do I find my artifacts in Nexus?
A: Search by your username or branch name

Q: What about releases?
A: Git tag triggers release version (no SNAPSHOT)
Speaker Notes:

These came from team survey
Any other questions?
Office hours: [Time/Date]


Slide 17: Resources
DOCUMENTATION & SUPPORT

📚 Migration Guide
   [Link to internal wiki/confluence]

💬 Slack Channel
   #engineering-maven-migration

👥 Office Hours
   Every Thursday 2-3pm
   [Meeting Room / Zoom Link]

📧 Email Support
   [team-lead@company.com]

🔗 Maven CI-Friendly Docs
   https://maven.apache.org/maven-ci-friendly.html
Speaker Notes:

All resources in one place
Bookmark the migration guide
Join Slack channel for updates
Office hours for hands-on help


Slide 18: Demo Time!
LIVE DEMONSTRATION

1. Show old workflow (pain points)
2. Show new POM structure
3. Create feature branch
4. Push and watch CI/CD
5. View artifacts in Nexus
6. Show Docker image tags
7. Local build demonstration

[Interactive Q&A follows]
Speaker Notes:

Switch to live demo
Have terminal and browser ready
Show actual GitLab pipeline
Show Nexus repository
Answer questions as they arise


Slide 19: Next Steps
THIS WEEK

✓ Parent POM migration complete
⊙ You: Update Maven settings.xml
⊙ You: Read migration guide
⊙ You: Test local build

NEXT WEEK

⊙ Component migrations begin
⊙ Watch for Slack notifications
⊙ Rebase your feature branches

WITHIN 4 WEEKS

⊙ All projects migrated
⊙ Old process deprecated
⊙ Documentation updated
Speaker Notes:

Clear timeline
Action items with dates
Team commitment needed
We're in this together


Slide 20: Thank You!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

           THANK YOU!

   Questions? Comments? Concerns?

           Let's discuss!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Resources: [wiki link]
Support: #engineering-maven-migration
Speaker Notes:

Open floor for questions
Capture concerns in notes
Schedule follow-ups if needed
Thank everyone for their time
