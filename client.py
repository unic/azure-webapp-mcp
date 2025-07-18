from fastmcp import Client
from fastmcp.client.transports import StreamableHttpTransport

client = Client(StreamableHttpTransport("http://0.0.0.0:8000/mcp/"))

async def test():
    async with client:
        result = await client.call_tool("hello", {"name": "John"})
        print(result)

if __name__ == "__main__":
    import asyncio
    asyncio.run(test())