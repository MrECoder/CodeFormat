3.3 Nexus Cleanup Task Configuration
Create Scheduled Cleanup Task:

Navigate to: Administration → System → Tasks
Click Create Task
Select Admin - Cleanup repositories using their cleanup policies

yamlTask Name: Cleanup Old Snapshots
Task Enabled: Yes
Task Frequency: Daily
Start Time: 02:00 AM

Cleanup:
  Repository: redacted (your snapshot repository)
