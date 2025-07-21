
from fastmcp import FastMCP
from middleware import custom_middleware

mcp = FastMCP("MyServer", stateless_http=True)

@mcp.tool
def hello(name: str) -> str:
    return f"Hello, {name}!"

app = mcp.http_app(middleware=custom_middleware, transport="streamable-http")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("server:app", host="0.0.0.0", port=8000)