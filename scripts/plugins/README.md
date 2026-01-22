# Script Plugins

Plugins allow extending behavior without modifying core scripts.

## Structure

plugins/
pre-ship/
post-ship/

## Rules

-   Scripts must be executable
-   Executed in alphabetical order
-   Failure aborts the parent script

## Example Use Cases

-   Slack notifications
-   Artifact signing
-   License scanning
-   Telemetry hooks
