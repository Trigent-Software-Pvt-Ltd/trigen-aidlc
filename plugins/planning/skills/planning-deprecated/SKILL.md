---
name: planning-deprecated
description: "DEPRECATED: The planning plugin has been renamed to aidlc"
---

# Plugin Deprecated

The `planning` plugin has been **renamed to `aidlc`**.

## Migration Steps

1. Uninstall this plugin: `/plugins uninstall planning`
2. Install the new plugin: `/plugins install aidlc`

## New Commands

The following commands are now available under `/aidlc-*`:
- `/aidlc-intent` - Create Intent documentation
- `/aidlc-elaborate` - Break Intent into Units and Tasks
- `/aidlc-design` - Domain/Logical Design and ADRs
- `/aidlc-verify` - Verify docs and transfer to Jira
- `/aidlc-bolt` - Implement a bolt with TDD
- `/aidlc-help` - Get help with AI-DLC methodology
