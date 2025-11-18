#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print section headers
print_section() {
    echo -e "\n${BLUE}▶ $1${NC}"
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print errors
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Banner
echo -e "${PURPLE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   Petstore MCP Server Test                                    ║
║   StreamableHTTP Transport                                    ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

MCP_ENDPOINT="http://localhost/v1/mcp"
HOST_HEADER="petstore-mcp.localhost.cosmonic.sh"

# Step 1: Initialize MCP session
print_section "Step 1: Initializing MCP session..."

cat > /tmp/mcp-init.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "initialize",
  "params": {
    "protocolVersion": "2024-11-05",
    "capabilities": {},
    "clientInfo": {
      "name": "test-client",
      "version": "1.0.0"
    }
  }
}
EOF

INIT_RESPONSE=$(curl -s -X POST \
  -H "Host: ${HOST_HEADER}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Accept: text/event-stream" \
  "${MCP_ENDPOINT}" \
  -d @/tmp/mcp-init.json)

SERVER_NAME=$(echo "$INIT_RESPONSE" | grep '^data:' | sed 's/^data: //' | jq -r '.result.serverInfo.name' 2>/dev/null)

if [ -n "$SERVER_NAME" ] && [ "$SERVER_NAME" != "null" ]; then
    print_success "Connected to MCP server: ${SERVER_NAME}"
    echo "$INIT_RESPONSE" | grep '^data:' | sed 's/^data: //' | jq '.result.capabilities'
else
    print_error "Failed to initialize MCP session"
    echo "$INIT_RESPONSE"
    exit 1
fi

# Step 2: List available tools
print_section "Step 2: Listing available tools..."

cat > /tmp/mcp-list-tools.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/list"
}
EOF

TOOLS_RESPONSE=$(curl -s -X POST \
  -H "Host: ${HOST_HEADER}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Accept: text/event-stream" \
  "${MCP_ENDPOINT}" \
  -d @/tmp/mcp-list-tools.json)

TOOLS=$(echo "$TOOLS_RESPONSE" | grep '^data:' | sed 's/^data: //' | jq -r '.result.tools[] | .name' 2>/dev/null)

if [ -n "$TOOLS" ]; then
    print_success "Available tools:"
    echo "$TOOLS" | head -10
    TOOL_COUNT=$(echo "$TOOLS" | wc -l | tr -d ' ')
    echo -e "${YELLOW}... and $((TOOL_COUNT - 10)) more tools${NC}"
else
    print_error "Failed to list tools"
    exit 1
fi

# Step 3: Call findPetsByStatus tool
print_section "Step 3: Calling get_pet_find_by_status tool..."

cat > /tmp/mcp-call-tool.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "tools/call",
  "params": {
    "name": "get_pet_find_by_status",
    "arguments": {
      "status": "available"
    }
  }
}
EOF

CALL_RESPONSE=$(curl -s -X POST \
  -H "Host: ${HOST_HEADER}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Accept: text/event-stream" \
  "${MCP_ENDPOINT}" \
  -d @/tmp/mcp-call-tool.json)

PETS=$(echo "$CALL_RESPONSE" | grep '^data:' | sed 's/^data: //' | jq -r '.result.content[0].text' 2>/dev/null)

if [ -n "$PETS" ] && [ "$PETS" != "null" ]; then
    print_success "Found available pets:"
    echo ""
    echo "$PETS" | jq -r '.[0:5] | .[] | "  • \(.name) - \(.status) (ID: \(.id))"'
    PET_COUNT=$(echo "$PETS" | jq -r '. | length')
    echo -e "\n${YELLOW}Total: ${PET_COUNT} pets with status 'available'${NC}"
else
    print_error "Failed to call tool"
    echo "$CALL_RESPONSE"
    exit 1
fi

# Step 4: Check Linkerd mesh metrics
print_section "Step 4: Checking Linkerd mesh metrics..."

if command -v linkerd &> /dev/null; then
    echo ""
    linkerd viz stat deployment -n petstore 2>/dev/null || echo "Linkerd viz not available"
fi

# Cleanup
rm -f /tmp/mcp-*.json

# Success banner
echo ""
echo -e "${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ✓ MCP Server Test Complete!                                 ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
echo "📖 MCP Protocol: StreamableHTTP Transport"
echo "🔗 Endpoint: ${MCP_ENDPOINT}"
echo "🎯 Tools tested: initialize, tools/list, tools/call"
echo ""
