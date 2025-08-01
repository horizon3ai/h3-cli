# NodeZero MCP Server – Locally Hosted Deployment Guide

The NodeZero MCP Server allows you to connect your IDE or AI assistant to Horizon3.ai APIs using your own infrastructure and LLM.\
Use this guide to quickly deploy a **locally hosted MCP Server** and start using NodeZero with your tools.

> **Important Notes:**
>
> - **All MCP server modes (stdio, SSE, HTTP) are local and single-user.**
>   - The server runs only on the system where you launch the Docker container.
>   - Using SSE/Streamable HTTP mode with this locally deployed MCP may present a **security risk** as this mode does not support runtime isolation and your JWT token will not be isolated to a session ID.
>   - Multi-user mode is **not yet supported**.
> - **Stdio mode is the primary, recommended deployment path.**
> - **VSCode / GitHub Copilot must use “Agent” mode** for MCP servers.\
>   *Do not use “Ask” or “Edit” modes—they will not leverage MCP tools.*

---

**Upcoming Release:**

Horizon3.ai will soon offer a **Hosted MCP Server** featuring:

- OAuth-based authentication
- Multi-user mode support
- Simplified, automated deployment
- Streamable HTTP as the default transport protocol

---

**Skip to IDE Configuration:**

If you already have:

- A valid H3 API Key
- Docker Desktop / Engine installed and running
- MCP-compatible IDE/Client (like VSCode or Cursor in Agent Mode)

…you can skip straight to pulling the NodeZero MCP Server container in [Step 3](#step-3-pull-the-nodezero-mcp-server-container) to begin using the NodeZero MCP Server.

---

## Table of Contents

- [1. Quick Start: Using an IDE to Deploy Locally in Stdio Mode (Recommended)](#1-quick-start-using-an-ide-to-deploy-locally-in-stdio-mode-recommended)
  - [Step 1: Generate an H3 API Key](#step-1-generate-an-h3-api-key)
  - [Step 2: Install and Run Docker Engine](#step-2-install-and-run-docker-engine)
  - [Step 3: Pull the NodeZero MCP Server Container](#step-3-pull-the-nodezero-mcp-server-container)
  - [Step 4: Running the NodeZero MCP Server (VSCode / Copilot in Agent Mode)](#step-4-running-the-nodezero-mcp-server-vscode--copilot-in-agent-mode)
    - [Step 4b: EU Region Setup](#eu-region-setup-step-4b)
- [2. Alternative Methods](#2-alternative-methods)
  - [Option 1: SSE or HTTP Mode](#option-1-sse-or-http-mode)
  - [Option 2: Manual Deployment](#option-2-manual-deployment)
- [3. Troubleshooting and Additional Deployment Tips](#3-troubleshooting-and-additional-deployment-tips)
- [4. Security and Best Practices](#4-security-and-best-practices)

---

## 1. Quick Start: Using an IDE to Deploy Locally in Stdio Mode (Recommended)

### Step 1: Generate an H3 API Key

1. Navigate to [Horizon3.ai Portal](https://portal.horizon3.ai/) (or [EU Portal](https://portal.horizon3ai.eu/)).
2. Click your **user profile icon** → **Settings** → **My Settings** tab.
3. Scroll to **API Keys** and click **Generate API Key**.
4. Choose the **User** role for full access.
5. Copy the key and save it before closing the modal.

### Step 2: Install and Run Docker Engine

Follow the official Docker Engine installation guide: [Install Docker Engine](https://docs.docker.com/engine/)

1. **Install Docker Engine** for your operating system.
2. **Start Docker Desktop or the Docker daemon**.
3. **Verify Docker version:**

```bash
docker --version
```

If you see a version number, Docker is installed successfully. 

4. **Verify Docker functionality:**

```bash
docker run hello-world
```

If you see the hello-world message, Docker is working correctly. See (#3-troubleshooting-and-additional-deployment-tips) if not working.

### Step 3: Pull the NodeZero MCP Server Container

```bash
docker pull horizon3ai/h3-mcp-server:latest
```

### Step 4: Running the NodeZero MCP Server (VSCode / Copilot in Agent Mode)

Follow these steps to configure VSCode to deploy and manage a locally hosted stdio MCP Server 
([VS Code MCP Server documentation](https://code.visualstudio.com/docs/copilot/chat/mcp-servers))

**Note:** We tested with **VS Code + GitHub Copilot Agent Mode**, but any MCP-compatible IDE or MCP client works similarly. Please reference documentation from your preferred method.

1. Open VS Code with GitHub Copilot enabled.
2. Open a **Copilot chat** and switch to **Agent** mode.
3. Click **Configure Tools** → **Add MCP Server > Command (stdio)**.
4. When prompted for **Enter Command**, type `docker` and press Enter.
5. Name your server (e.g., `NodeZeroMCP`) and press Enter.
6. VS Code will open a `mcp.json` or `settings.json` tab. If not, press `Cmd+Shift+P` (Mac) / `Ctrl+Shift+P` (Windows/Linux), type **Open Settings JSON**, and select **Preferences: Open User Settings (JSON)**.
7. Update your configuration as follows. Use the `inputs` feature to securely prompt for the API key at runtime, keeping it out of the file and reducing risk of accidental exposure.

```json
"<your-mcp-server-name>": {
  "type": "stdio",
  "command": "docker",
  "args": [
    "run",
    "--pull", "always",
    "-i",
    "--rm",
    "-e", "H3_API_KEY",
    "horizon3ai/h3-mcp-server:latest"
  ],
  "env": {
    "H3_API_KEY": "${input:h3_api_key}"
  },
  "inputs": [
    {
      "type": "promptString",
      "id": "h3_api_key",
      "description": "H3 API Key",
      "password": true
    }
  ]
}
```

> Replace `<your-mcp-server-name>` with the name you assigned in Step 4.
> Input H3 API Key

#### Step 4b: EU Region Setup

```json
"<your-mcp-server-name>": {
  "type": "stdio",
  "command": "docker",
  "args": [
    "run",
    "--pull", "always",
    "-i",
    "--rm",
    "-e", "H3_API_KEY",
    "-e", "H3_GQL_URL=https://api.horizon3ai.eu/v1/graphql",
    "-e", "H3_AUTH_URL=https://api.horizon3ai.eu/v1/auth",
    "horizon3ai/h3-mcp-server:latest"
  ],
  "env": {
    "H3_API_KEY": "${input:h3_api_key}"
  },
  "inputs": [
    {
      "type": "promptString",
      "id": "h3_api_key",
      "description": "H3 API Key",
      "password": true
    }
  ]
}
```

VS Code will securely prompt for your API key, pull the latest container, and connect via stdio in Agent Mode.


---

## 2. Alternative Methods

### Option 1: SSE or HTTP Mode

**Warning:** Use SSE/Streamable HTTP **only if your IDE or GenAI client cannot use stdio**. Using SSE/Streamable HTTP mode with this locally deployed MCP may present a **security risk** as this mode does not support runtime isolation and your JWT token will not be isolated to a session ID.

**Notes:**

- Single-user only; no multi-user hosting.
- Server runs locally.

**Purpose:**

- Provides persistent connections.
- Required by some GenAI chat clients or cloud IDEs.

**SSE Mode (IDE Configuration Example)**

```json
"<your-mcp-server-name>": {
  "type": "sse",
  "command": "docker",
  "args": [
    "run", "-i", "--rm",
    "-e", "H3_API_KEY",
    "horizon3ai/h3-mcp-server:latest",
    "sse", "8000"
  ],
  "env": {
    "H3_API_KEY": "${input:h3_api_key}"
  },
  "inputs": [
    {
      "type": "promptString",
      "id": "h3_api_key",
      "description": "H3 API Key",
      "password": true
    }
  ]
}
```

**Streamable HTTP Mode (IDE Configuration Example)**

```json
"<your-mcp-server-name>": {
  "type": "http",
  "command": "docker",
  "args": [
    "run", "-i", "--rm",
    "-e", "H3_API_KEY",
    "horizon3ai/h3-mcp-server:latest",
    "streamable-http", "8000"
  ],
  "env": {
    "H3_API_KEY": "${input:h3_api_key}"
  },
  "inputs": [
    {
      "type": "promptString",
      "id": "h3_api_key",
      "description": "H3 API Key",
      "password": true
    }
  ]
}
```

### Option 2: Manual Deployment

Run the container manually with a descriptive name like `<your-container-name>`:

```bash
docker run -d --name <your-container-name> \
  -e H3_API_KEY={your-key-here} \
  horizon3ai/h3-mcp-server:latest
```

Stop it with:

```bash
docker stop <your-container-name>
```

**Stdio Mode (Attach-Only via IDE)**

```json
"<your-mcp-server-name>": {
  "type": "stdio",
  "command": "docker",
  "args": ["run", "-i", "--rm", "horizon3ai/h3-mcp-server:latest"]
}
```

**SSE Mode (Attach-Only via IDE)**

```json
"<your-mcp-server-name>": {
  "type": "sse",
  "url": "http://localhost:8000/sse"
}
```

**Streamable HTTP Mode (Attach-Only via IDE)**

```json
"<your-mcp-server-name>": {
  "type": "http",
  "url": "http://localhost:8000/mcp"
}
```

---

## 3. Troubleshooting and Additional Deployment Tips

### Diagnosing Docker Issues

Check Docker Service state:

```bash
sudo systemctl status docker
```

- Inactive/failed → service issue.
- Active but CLI fails → daemon issue.

**Service Commands:**

```bash
sudo systemctl start docker      # Starts the service and daemon
sudo systemctl stop docker       # Stops the service and daemon
sudo systemctl status docker     # Shows service + daemon status
sudo systemctl enable docker     # Auto-start daemon at boot
```

**Restart Docker Daemon:**

```bash
sudo systemctl restart docker
pgrep -x dockerd || sudo dockerd
```

If `dockerd` is run manually, it stops when terminal closes. Enable it for auto-start.

### Run MCP Server in Background

```bash
docker run -d --name <your-container-name> \
  -e H3_API_KEY={your-key-here} \
  horizon3ai/h3-mcp-server:latest
```

Stop later:

```bash
docker stop <your-container-name>
```

### Clean Up Containers and Keys

```bash
docker rm <your-container-name>
unset H3_API_KEY
```

### Use Single-User Mode

Each container should use one API key.



## Available Tools

The MCP server provides the following tools to AI assistants:

1. **`fetch_h3_graphql_docs`**: Get GraphQL schema documentation for constructing queries
2. **`run_h3_graphql_request`**: Execute GraphQL queries against the H3 API

---

## 4. Security and Best Practices

- **Use single-user mode**: A single instance of the H3 MCP server is designed to use a single H3 API key.
- **Pass keys securely**: The only way to pass the API key to the server is via the `-e H3_API_KEY={your-key-here}` option on the `docker run` command.
- **Restrict network**: run locally or behind VPN/firewall.
- **Stop/remove containers** when not in use.
- **Rotate keys regularly** and test before use in production.
- **Create GraphQL examples**: Prepare sample queries for fetching test data or triggering NodeZero assessments.
- **Leverage system prompts**: Tailor system prompts to your specific use cases to improve response accuracy and reduce token usage.

