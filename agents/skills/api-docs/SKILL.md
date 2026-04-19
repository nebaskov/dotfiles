---
name: api-docs
description: Generate API documentation in .md format for a given module or set of endpoints. Use when the user asks to document an API, create API reference, or describe endpoints.
argument-hint: [module-or-directory-path]
allowed-tools: Read, Grep, Glob, Agent
---

# API Documentation Generator

Generate a comprehensive `.md` file documenting REST API endpoints for the specified module or directory.

## Process

1. **Discover endpoints**: Use Glob and Grep to find all router/view files, schemas, and models in the target module (`$ARGUMENTS`). Identify every HTTP endpoint (GET, POST, PUT, PATCH, DELETE), its path, status codes, dependencies, and request/response schemas.

2. **Analyze schemas**: Read all Pydantic models (or equivalent schemas) used for request bodies and responses. Determine field names, types, whether they are required or optional, and default values.

3. **Analyze middleware and dependencies**: Identify authentication requirements, authorization checks (e.g. ownership verification), and any other dependency injections applied to endpoints.

4. **Analyze business logic**: Read CRUD/service layer to understand constraints (file size limits, supported MIME types, cascading deletes, side effects like indexing).

5. **Generate documentation**: Write a single `.md` file into the `docs/` directory of the project (create the directory if needed).

## Documentation Structure

The output `.md` file MUST follow this structure:

```
# {Module Name} API

Brief description of what the module does.

Base prefix, authentication info.

---

## {N}. {Resource Group}

### {N.M}. {Endpoint Title}

Short description of what the endpoint does.

**HTTP request:**
{METHOD} {/full/path}

**Path parameters:** (if any)

| Parameter | Type | Description |
|---|---|---|

**Request body fields:** (if any)

| Parameter | Type | Description |
|---|---|---|

**Response fields:**

| Parameter | Type | Description |
|---|---|---|

**Request example:** (for POST/PUT/PATCH)

```json
{ ... }
```

**Response example:** (for endpoints returning a body)

```json
{ ... }
```

**Response codes:**

| Code | Description |
|---|---|

---
```

## Formatting Rules

- **Language**: Write all documentation in English if not specified otherwise.
- **Tables**: Use Markdown tables for all parameter descriptions. Every table MUST have three columns: `Parameter`, `Type`, `Description`.
- **Required/Optional**: Indicate in the `Description` column whether a parameter is required or optional, and note default values if any.
- **Types**: Use precise types — `integer`, `string`, `boolean`, `datetime`, `array [object]`, `integer | null`, etc.
- **Path parameters**: Document in a separate table under `Path parameters`.
- **HTTP method + path**: Always show the full path starting from the version prefix (e.g. `/v1/...`).
- **Response codes**: Include a table of all possible HTTP status codes for each endpoint, with short descriptions.
- **Examples**: Provide JSON request/response examples for POST, PUT, and PATCH endpoints.
- **Grouping**: Group endpoints by resource (e.g. Chats, Files, Users). Number sections hierarchically (1, 1.1, 1.2, ..., 2, 2.1, ...).
- **Separators**: Use `---` horizontal rules between endpoints.
- **Common errors section**: At the end, include a summary table of all error codes used across the API.
- **Constraints**: Document any business constraints (file size limits, supported file types, cascading behavior on delete, etc.) inline with the relevant endpoint.
- **No code references**: Do not include file paths, line numbers, or source code references in the output documentation — it should be a clean API reference.
