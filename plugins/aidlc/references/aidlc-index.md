# AIDLC Document Index

The AIDLC Document Index is a single Confluence page that serves as the canonical registry of all AIDLC Feature documents, regardless of the backend used to store the document itself.

## Location

- **Space**: `<CONFLUENCE_SPACE_KEY>` (from `aidlc.config.yaml`; run `/aidlc-init`)
- **Page ID**: `<FEATURE_INDEX_PAGE_ID>`
- **Page title**: `Features Index`
- **URL**: https://<ATLASSIAN_CLOUD_ID>/wiki/spaces/<CONFLUENCE_SPACE_KEY>/pages/<FEATURE_INDEX_PAGE_ID>/Features+Index

## Purpose

Provides a single human-readable overview for anyone who wants to know:
- What Features exist across all backends (GitLab, Linear, Confluence)
- Where to find each Feature's documentation
- Which team owns it and when it was created

## Table Structure

| Feature | Product / Project | Backend | Location | Phase | Team | Created |
|--------|------------------|---------|----------|-------|------|---------|

### Column Definitions

| Column | Description | Example |
|--------|-------------|---------|
| Feature | Feature name, hyperlinked to the document | [Auth Overhaul](https://gitlab.com/...) |
| Product / Project | Product or project this Feature belongs to | StudentSafe |
| Backend | Documentation backend used | GitLab / Linear / Confluence |
| Location | Backend-specific link or identifier | [MR #42](url) / [Initiative](url) / [Page](url) |
| Phase | AIDLC phase at time of registration | Feature |
| Team | Owning team | Platform / Frontend / Backend |
| Created | Date the Feature was registered | 2026-03-02 |

## Maintenance

- **Created and updated** automatically by `/aidlc-intent` when a Feature is approved
- **One row per Feature** — subsequent skills do not update this index
- The index is always stored in Confluence regardless of which backend the Feature itself uses
- If the page does not exist when a new Feature is created, `/aidlc-intent` creates it

## Initial Page Content

When creating the index page for the first time, use this content:

```markdown
# Features Index

This page is the canonical registry of all AI-DLC Feature documents. It is maintained
automatically by the `/aidlc-intent` skill and provides a single point of reference
for locating Feature documentation across all backends (GitLab, Linear, and Confluence).

> This index is updated when each Feature is created and approved. For current phase
> status, follow the link to the Feature document itself.

| Feature | Product / Project | Backend | Location | Phase | Team | Created |
|--------|------------------|---------|----------|-------|------|---------|
```
