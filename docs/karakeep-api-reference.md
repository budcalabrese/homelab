# Karakeep API Reference

## Overview

Karakeep provides a REST API at `/api/v1/` for programmatic access to bookmarks, tags, and lists.

## Authentication

All API requests require Bearer token authentication.

**Headers:**
```bash
Authorization: Bearer YOUR_API_TOKEN_HERE
Content-Type: application/json
```

**Generating API Token:**
1. Open Karakeep UI: http://localhost:3000
2. Navigate to Settings → API Tokens
3. Click "Create New Token"
4. Give it a name (e.g., "n8n Automation")
5. Copy the generated token

**Environment Variable:**
```bash
export KARAKEEP_API_TOKEN="your_token_here"
```

## Base URL

```
http://localhost:3000/api/v1
```

For n8n workflows running in Docker:
```
http://karakeep:3000/api/v1
```

## Bookmark Endpoints

### Get All Bookmarks

**Endpoint:** `GET /bookmarks`

**Query Parameters:**
- `limit` (integer): Number of bookmarks to return (default: 50, max: 100)
- `cursor` (string): Pagination cursor for next page
- `includeContent` (boolean): Include full bookmark content (default: true)
  - **Note**: Starting from next release, defaults to false

**Example Request:**
```bash
curl -H "Authorization: Bearer $KARAKEEP_API_TOKEN" \
  "http://localhost:3000/api/v1/bookmarks?limit=20&includeContent=true"
```

**Example Response:**
```json
{
  "bookmarks": [
    {
      "id": "bookmark_abc123",
      "type": "link",
      "url": "https://example.com/article",
      "title": "Example Article",
      "description": "Article description",
      "content": "Full article text...",
      "tags": [
        {
          "id": "tag_xyz",
          "name": "ai"
        }
      ],
      "createdAt": "2024-12-08T14:30:00Z",
      "updatedAt": "2024-12-08T14:30:00Z",
      "archived": false,
      "favourited": false
    }
  ],
  "nextCursor": "cursor_token_here"
}
```

### Search Bookmarks

**Endpoint:** `GET /bookmarks/search`

**Query Parameters:**
- `q` (string): Search query
- `tags` (string): Comma-separated tag names to filter by
- `limit` (integer): Number of results
- `includeContent` (boolean): Include full content

**Example: Get bookmarks by tag**
```bash
# Get all AI-tagged bookmarks from last 24 hours
curl -H "Authorization: Bearer $KARAKEEP_API_TOKEN" \
  "http://localhost:3000/api/v1/bookmarks/search?tags=ai&limit=100"
```

**Example: Multiple tags**
```bash
# Get bookmarks tagged with "ai" OR "finance"
curl -H "Authorization: Bearer $KARAKEEP_API_TOKEN" \
  "http://localhost:3000/api/v1/bookmarks/search?tags=ai,finance&limit=100"
```

### Get Single Bookmark

**Endpoint:** `GET /bookmarks/{bookmarkId}`

**Example:**
```bash
curl -H "Authorization: Bearer $KARAKEEP_API_TOKEN" \
  "http://localhost:3000/api/v1/bookmarks/bookmark_abc123"
```

### Create Bookmark

**Endpoint:** `POST /bookmarks`

**Request Body (Link):**
```json
{
  "type": "link",
  "url": "https://example.com/article",
  "title": "Optional Title Override",
  "note": "Personal note about this bookmark"
}
```

**Request Body (Text/Note):**
```json
{
  "type": "text",
  "title": "My Note Title",
  "content": "Note content here..."
}
```

**Example:**
```bash
curl -X POST \
  -H "Authorization: Bearer $KARAKEEP_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"link","url":"https://example.com"}' \
  "http://localhost:3000/api/v1/bookmarks"
```

### Update Bookmark

**Endpoint:** `PATCH /bookmarks/{bookmarkId}`

**Request Body:**
```json
{
  "title": "Updated Title",
  "note": "Updated note",
  "archived": false,
  "favourited": true
}
```

**Example:**
```bash
curl -X PATCH \
  -H "Authorization: Bearer $KARAKEEP_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"favourited":true}' \
  "http://localhost:3000/api/v1/bookmarks/bookmark_abc123"
```

### Delete Bookmark

**Endpoint:** `DELETE /bookmarks/{bookmarkId}`

**Example:**
```bash
curl -X DELETE \
  -H "Authorization: Bearer $KARAKEEP_API_TOKEN" \
  "http://localhost:3000/api/v1/bookmarks/bookmark_abc123"
```

## Tag Endpoints

### Get All Tags

**Endpoint:** `GET /tags`

**Example:**
```bash
curl -H "Authorization: Bearer $KARAKEEP_API_TOKEN" \
  "http://localhost:3000/api/v1/tags"
```

**Response:**
```json
{
  "tags": [
    {
      "id": "tag_1",
      "name": "ai",
      "count": 42
    },
    {
      "id": "tag_2",
      "name": "finance",
      "count": 18
    }
  ]
}
```

### Attach Tags to Bookmark

**Endpoint:** `POST /bookmarks/{bookmarkId}/tags`

**Request Body:**
```json
{
  "tagNames": ["podcasted", "podcasted-2024-12-08"]
}
```

**Example:**
```bash
curl -X POST \
  -H "Authorization: Bearer $KARAKEEP_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tagNames":["podcasted","podcasted-2024-12-08"]}' \
  "http://localhost:3000/api/v1/bookmarks/bookmark_abc123/tags"
```

### Detach Tags from Bookmark

**Endpoint:** `DELETE /bookmarks/{bookmarkId}/tags`

**Request Body:**
```json
{
  "tagIds": ["tag_1", "tag_2"]
}
```

## Filtering for Workflows

### Use Case 1: Get Recent Bookmarks by Tag (for Daily Podcast)

Get all bookmarks with specific tags added in the last 24 hours:

```bash
# Note: Karakeep doesn't have native date filtering in API
# Use get all bookmarks and filter in n8n based on createdAt field

curl -H "Authorization: Bearer $KARAKEEP_API_TOKEN" \
  "http://localhost:3000/api/v1/bookmarks/search?tags=ai&limit=100&includeContent=true"
```

In n8n, filter by date:
```javascript
// Filter function in n8n
const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
return items.filter(item => {
  const created = new Date(item.json.createdAt);
  return created > oneDayAgo;
});
```

### Use Case 2: Get Old Bookmarks for Cleanup

Get podcasted bookmarks older than 7 days that are NOT favourited:

```bash
# Get all podcasted bookmarks
curl -H "Authorization: Bearer $KARAKEEP_API_TOKEN" \
  "http://localhost:3000/api/v1/bookmarks/search?tags=podcasted&limit=100"
```

Filter in n8n:
```javascript
// Filter for cleanup
const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
return items.filter(item => {
  const created = new Date(item.json.createdAt);
  return created < sevenDaysAgo && !item.json.favourited;
});
```

## Data Structure Notes

**Bookmark Object Fields:**
- `id` - Unique identifier
- `type` - "link", "text", or "asset"
- `url` - Source URL (for link type)
- `title` - Bookmark title
- `description` - Auto-generated description
- `content` - Full article content (if scraped)
- `note` - User's personal note
- `tags` - Array of tag objects
- `createdAt` - ISO 8601 timestamp
- `updatedAt` - ISO 8601 timestamp
- `archived` - Boolean
- `favourited` - Boolean (starred)

**Important for Podcast Workflow:**
- Use `tags` array to filter bookmarks
- Use `createdAt` to find recent bookmarks
- Use `favourited` field to protect bookmarks from cleanup
- Use `content` field for podcast source material
- Use `url` field for show notes links

## Rate Limiting

Karakeep doesn't have explicit rate limiting documentation. Best practices:
- Don't exceed 100 requests per minute
- Use pagination with cursors for large result sets
- Cache results when possible

## Error Responses

**401 Unauthorized:**
```json
{
  "error": "Invalid or missing API token"
}
```

**404 Not Found:**
```json
{
  "error": "Bookmark not found"
}
```

**500 Internal Server Error:**
```json
{
  "error": "Internal server error"
}
```

## Testing API Access

**Quick test:**
```bash
# Set your token
export KARAKEEP_API_TOKEN="your_token_here"

# Test get bookmarks
curl -H "Authorization: Bearer $KARAKEEP_API_TOKEN" \
  "http://localhost:3000/api/v1/bookmarks?limit=1" | jq .

# Test get tags
curl -H "Authorization: Bearer $KARAKEEP_API_TOKEN" \
  "http://localhost:3000/api/v1/tags" | jq .
```

## Python Client Usage

If using Python for scripting:

```bash
pip install karakeep-python-api
```

```python
import os
from karakeep_python_api import KarakeepAPI

# Set environment variables
os.environ['KARAKEEP_PYTHON_API_ENDPOINT'] = 'http://localhost:3000/api/v1/'
os.environ['KARAKEEP_PYTHON_API_KEY'] = 'your_token_here'

# Initialize client
client = KarakeepAPI()

# Get bookmarks
bookmarks = client.get_all_bookmarks(limit=10)

# Create bookmark
client.create_a_new_bookmark(
    data='{"type": "link", "url": "https://example.com"}'
)

# Attach tags
client.attach_tags_to_a_bookmark(
    bookmark_id="bookmark_123",
    tag_names=["ai", "podcasted"]
)
```

## References

- [Karakeep GitHub](https://github.com/karakeep-app/karakeep)
- [Karakeep Documentation](https://docs.karakeep.app/)
- [Python API Client](https://github.com/thiswillbeyourgithub/karakeep_python_api)
- [PyPI Package](https://pypi.org/project/karakeep-python-api/)

---

**Last Updated:** December 8, 2024
