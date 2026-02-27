---
name: backlog-api
description: Interact with Backlog project management via REST API. Search issues, get details, add comments, and browse wikis using curl.
allowed-tools: Bash(curl:*)
---

# Backlog API Skill

Interact with Backlog (nulab) project management system via REST API.

## Prerequisites

Set environment variables before use:

```bash
export BACKLOG_DOMAIN="your-space.backlog.com"
export BACKLOG_API_KEY="your-api-key"
```

## Base URL

All endpoints use: `https://${BACKLOG_DOMAIN}/api/v2`

## Common Operations

### Get Issue by Key

```bash
curl -s "https://${BACKLOG_DOMAIN}/api/v2/issues/PROJECT-123?apiKey=${BACKLOG_API_KEY}" | jq .
```

### Search Issues

```bash
# By project ID
curl -s "https://${BACKLOG_DOMAIN}/api/v2/issues?apiKey=${BACKLOG_API_KEY}&projectId[]=12345&count=20" | jq .

# By keyword
curl -s "https://${BACKLOG_DOMAIN}/api/v2/issues?apiKey=${BACKLOG_API_KEY}&projectId[]=12345&keyword=bug" | jq .

# By status (1=Open, 2=In Progress, 3=Resolved, 4=Closed)
curl -s "https://${BACKLOG_DOMAIN}/api/v2/issues?apiKey=${BACKLOG_API_KEY}&projectId[]=12345&statusId[]=1&statusId[]=2" | jq .

# By assignee
curl -s "https://${BACKLOG_DOMAIN}/api/v2/issues?apiKey=${BACKLOG_API_KEY}&projectId[]=12345&assigneeId[]=67890" | jq .
```

### Get Issue Comments

```bash
curl -s "https://${BACKLOG_DOMAIN}/api/v2/issues/PROJECT-123/comments?apiKey=${BACKLOG_API_KEY}" | jq .
```

### Add Comment to Issue

```bash
curl -s -X POST "https://${BACKLOG_DOMAIN}/api/v2/issues/PROJECT-123/comments?apiKey=${BACKLOG_API_KEY}" \
  -d "content=This is a comment" | jq .
```

### Get Project List

```bash
curl -s "https://${BACKLOG_DOMAIN}/api/v2/projects?apiKey=${BACKLOG_API_KEY}" | jq '.[] | {id, projectKey, name}'
```

### Get Wiki Pages

```bash
# List wikis in a project
curl -s "https://${BACKLOG_DOMAIN}/api/v2/wikis?apiKey=${BACKLOG_API_KEY}&projectIdOrKey=PROJECT" | jq '.[] | {id, name}'

# Get wiki content
curl -s "https://${BACKLOG_DOMAIN}/api/v2/wikis/12345?apiKey=${BACKLOG_API_KEY}" | jq .
```

### Get Users

```bash
curl -s "https://${BACKLOG_DOMAIN}/api/v2/users?apiKey=${BACKLOG_API_KEY}" | jq '.[] | {id, name, mailAddress}'
```

## Useful jq Patterns

```bash
# Issue summary with status
curl -s "https://${BACKLOG_DOMAIN}/api/v2/issues?apiKey=${BACKLOG_API_KEY}&projectId[]=12345&count=10" | \
  jq '.[] | {key: .issueKey, summary, status: .status.name, assignee: .assignee.name}'

# Count issues by status
curl -s "https://${BACKLOG_DOMAIN}/api/v2/issues?apiKey=${BACKLOG_API_KEY}&projectId[]=12345&count=100" | \
  jq 'group_by(.status.name) | map({status: .[0].status.name, count: length})'
```

## API Reference

Full documentation: https://developer.nulab.com/docs/backlog/
