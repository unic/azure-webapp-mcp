# azure-webapp-mcp

Template Repository to use Azure Web Apps as MCP Server (Python FastMCP)

For more details, see: [Azure Web App](https://uniccom.atlassian.net/wiki/spaces/INNOLAB/pages/575571284/Azure+Web+App)

For the Azure Web App approach of hosting a Python MCP Server, we're more flexible and we can use the officially supported FastMCP library for this:

https://github.com/jlowin/fastmcp

## Prerequisites

- Python version 3.11 or higher
- **uv** (https://docs.astral.sh/uv/): `brew install uv`
- **Azure CLI**  
  The easiest is to install the Azure CLI Tools using Homebrew:
  - Azure CLI: `brew update && brew install azure-cli`
  - Azure Developer CLI: `brew tap azure/azd && brew install azd`
- **Docker desktop** https://docs.docker.com/desktop/setup/install/mac-install/ or **Colima** (MIT License)
  ```bash
  brew install colima
  brew install docker  # docker is still required for colima
  ```

For Colima you also need BuildX:
```bash
brew install docker-buildx
```

Then to ensure Buildx plugins are available in the docker CLI, especially for Colima, you need to update `~/.docker/config.json` and add this:
```json
"cliPluginsExtraDirs": ["$HOMEBREW_PREFIX/lib/docker/cli-plugins"]
```
You probably need to replace `$HOMEBREW_PREFIX` with the output of `brew --prefix`

## Setup locally

1. Create a repo based on our template: https://github.com/unic/azure-webapp-mcp
2. Run `uv sync`
3. Then:
   ```bash
   uv run uvicorn server:app --host 0.0.0.0 --port 8000
   ```
   to start the server locally at port 8000.

You can then run `uv run client.py` in a new terminal to see if it works:
```
CallToolResult(content=[TextContent(type='text', text='Hello, John!', annotations=None, meta=None)], structured_content={'result': 'Hello, John!'}, data='Hello, John!', is_error=False)
```

## Local Debugging

You can run the local server in debug mode in VSCode (instead of using `uv run…`), set a breakpoint somewhere and then again run the client in another terminal. The execution should stop at the breakpoint.

## Setup Resources in Azure

Follow these steps in order:

1. https://uniccom.atlassian.net/wiki/spaces/INNOLAB/pages/576061498
2. https://uniccom.atlassian.net/wiki/spaces/INNOLAB/pages/576028690
3. https://uniccom.atlassian.net/wiki/spaces/INNOLAB/pages/576028740

## Deploy to Azure

Once all resources are created, we can deploy the MCP server to our Azure Web App:

```bash
./deploy.sh
```

If there is an issue with the permissions, you might need to run:
```bash
chmod +x deploy.sh
```

It will then ask you to login, choose a subscription and enter:
- Name of Resource Group
- Name of the Container Registry
- Name of the Web App
- Tag of your new docker image
- Name of the new docker image

Once deployed, restart the Web App in the portal.

## Testing the deployed MCP-Server

Now you can test the deployed Server in different ways, for example:

### Using the client.py
Change the URL to the domain of the web app, e.g.:
```
https://test-mcp-web-app-gzfkgbgefud0cbc3.switzerlandnorth-01.azurewebsites.net/mcp/
```

### Using VSCode
CMD+Shift+P using "MCP: Add Server", HTTP, enter the whole url with `/mcp/` at the end, give it a name, and choose workspace or local. Then in agent mode in the chat window you can test it. The entry in the config in VSCode should look like this:

```json
"test-mcp-web-app": {
    "url": "https://test-mcp-web-app-gzfkgbgefud0cbc3.switzerlandnorth-01.azurewebsites.net/mcp/",
    "type": "http"
}
```

### Using Claude desktop
Open the `claude_desktop_config.json` and add this to the "mcpServers" object:

```json
"test-mcp-web-app": {
  "command": "npx",
  "args": [
    "mcp-remote",
    "https://test-mcp-web-app-gzfkgbgefud0cbc3.switzerlandnorth-01.azurewebsites.net/mcp/"
  ]
}
```

### Using Copilot Studio
Following this guide: https://uniccom.atlassian.net/wiki/spaces/INNOLAB/pages/575636509/Copilot+Studio+MCP, you can add it to Copilot Studio.
