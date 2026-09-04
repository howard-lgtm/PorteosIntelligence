#!/bin/bash

# Porteos Intelligence — MLX Bionic Handover Setup Script
# Validates development environment and project readiness
# Run with: chmod +x setup.sh && ./setup.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
WARNINGS=0

# Header
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  PORTEOS INTELLIGENCE — MLX BIONIC HANDOVER SETUP"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Function: Print status
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "pass" ]; then
        echo -e "${GREEN}✅ PASS${NC} - $message"
        ((CHECKS_PASSED++))
    elif [ "$status" = "fail" ]; then
        echo -e "${RED}❌ FAIL${NC} - $message"
        ((CHECKS_FAILED++))
    elif [ "$status" = "warn" ]; then
        echo -e "${YELLOW}⚠️  WARN${NC} - $message"
        ((WARNINGS++))
    elif [ "$status" = "info" ]; then
        echo -e "${BLUE}ℹ️  INFO${NC} - $message"
    fi
}

# Function: Check command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ============================================================================
# 1. SYSTEM REQUIREMENTS
# ============================================================================

echo "────────────────────────────────────────────────────────────────"
echo "1. SYSTEM REQUIREMENTS"
echo "────────────────────────────────────────────────────────────────"

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
MACOS_MAJOR=$(echo "$MACOS_VERSION" | cut -d. -f1)
MACOS_MINOR=$(echo "$MACOS_VERSION" | cut -d. -f2)

if [ "$MACOS_MAJOR" -ge 14 ] && [ "$MACOS_MINOR" -ge 6 ]; then
    print_status "pass" "macOS $MACOS_VERSION (14.6+ required)"
elif [ "$MACOS_MAJOR" -ge 15 ]; then
    print_status "pass" "macOS $MACOS_VERSION (14.6+ required)"
else
    print_status "fail" "macOS $MACOS_VERSION (14.6+ required for SwiftData)"
fi

# Check architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    print_status "pass" "Apple Silicon detected (arm64)"
elif [ "$ARCH" = "x86_64" ]; then
    print_status "pass" "Intel Mac detected (x86_64)"
else
    print_status "warn" "Unknown architecture: $ARCH"
fi

# Check available RAM
TOTAL_RAM=$(sysctl -n hw.memsize)
TOTAL_RAM_GB=$((TOTAL_RAM / 1024 / 1024 / 1024))
if [ "$TOTAL_RAM_GB" -ge 16 ]; then
    print_status "pass" "${TOTAL_RAM_GB}GB RAM (16GB+ recommended)"
elif [ "$TOTAL_RAM_GB" -ge 8 ]; then
    print_status "warn" "${TOTAL_RAM_GB}GB RAM (8GB minimum, 16GB+ recommended)"
else
    print_status "fail" "${TOTAL_RAM_GB}GB RAM (8GB minimum required)"
fi

echo ""

# ============================================================================
# 2. DEVELOPMENT TOOLS
# ============================================================================

echo "────────────────────────────────────────────────────────────────"
echo "2. DEVELOPMENT TOOLS"
echo "────────────────────────────────────────────────────────────────"

# Check Xcode
if command_exists xcodebuild; then
    XCODE_VERSION=$(xcodebuild -version | head -n1 | awk '{print $2}')
    XCODE_MAJOR=$(echo "$XCODE_VERSION" | cut -d. -f1)
    
    if [ "$XCODE_MAJOR" -ge 16 ]; then
        print_status "pass" "Xcode $XCODE_VERSION (16.6+ required)"
    elif [ "$XCODE_MAJOR" -ge 15 ]; then
        print_status "warn" "Xcode $XCODE_VERSION (16.6+ recommended)"
    else
        print_status "fail" "Xcode $XCODE_VERSION (16.6+ required)"
    fi
else
    print_status "fail" "Xcode not found (install from Mac App Store)"
fi

# Check Swift
if command_exists swift; then
    SWIFT_VERSION=$(swift --version | head -n1 | awk '{print $4}')
    print_status "pass" "Swift $SWIFT_VERSION"
else
    print_status "fail" "Swift not found (comes with Xcode)"
fi

# Check Git
if command_exists git; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    print_status "pass" "Git $GIT_VERSION"
else
    print_status "fail" "Git not found (install with: brew install git)"
fi

echo ""

# ============================================================================
# 3. FONTS
# ============================================================================

echo "────────────────────────────────────────────────────────────────"
echo "3. REQUIRED FONTS"
echo "────────────────────────────────────────────────────────────────"

# Check JetBrains Mono font
if system_profiler SPFontsDataType 2>/dev/null | grep -q "JetBrains Mono"; then
    print_status "pass" "JetBrains Mono font installed"
else
    print_status "fail" "JetBrains Mono font missing"
    echo "         → Download: https://www.jetbrains.com/lp/mono/"
    echo "         → Install: Double-click .ttf files in Downloads"
fi

echo ""

# ============================================================================
# 4. PROJECT FILES
# ============================================================================

echo "────────────────────────────────────────────────────────────────"
echo "4. PROJECT FILES"
echo "────────────────────────────────────────────────────────────────"

# Check Xcode project
if [ -f "PorteosIntelligence.xcodeproj/project.pbxproj" ]; then
    print_status "pass" "Xcode project found"
else
    print_status "fail" "PorteosIntelligence.xcodeproj not found"
fi

# Check key Swift files
KEY_FILES=(
    "PorteosIntelligence/PorteosIntelligenceApp.swift"
    "PorteosIntelligence/Models/PropertyDeal.swift"
    "PorteosIntelligence/Calculators/RealEstateCalculator.swift"
    "PorteosIntelligence/Services/LLMAnalysisService.swift"
)

for file in "${KEY_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_status "pass" "$(basename "$file")"
    else
        print_status "fail" "$file missing"
    fi
done

echo ""

# ============================================================================
# 5. DOCUMENTATION
# ============================================================================

echo "────────────────────────────────────────────────────────────────"
echo "5. HANDOVER DOCUMENTATION"
echo "────────────────────────────────────────────────────────────────"

# Check Phase 1 docs
PHASE1_DOCS=(
    "README.md"
    "DEVELOPER_SETUP.md"
    "ARCHITECTURE.md"
    "EXTERNAL_SERVICES.md"
    "DATA_MODEL_GUIDE.md"
)

for doc in "${PHASE1_DOCS[@]}"; do
    if [ -f "$doc" ]; then
        print_status "pass" "Phase 1: $doc"
    else
        print_status "fail" "Phase 1: $doc missing"
    fi
done

echo ""

# Check Phase 2 docs
PHASE2_DOCS=(
    "SWIFTDATA_MIGRATION.md"
    "LLM_INTEGRATION.md"
    "CALCULATOR_SYSTEM.md"
    "BROWSER_EXTENSION_GUIDE.md"
    "MULTI_WINDOW_SYSTEM.md"
)

for doc in "${PHASE2_DOCS[@]}"; do
    if [ -f "$doc" ]; then
        print_status "pass" "Phase 2: $doc"
    else
        print_status "fail" "Phase 2: $doc missing"
    fi
done

echo ""

# ============================================================================
# 6. GIT REPOSITORY
# ============================================================================

echo "────────────────────────────────────────────────────────────────"
echo "6. GIT REPOSITORY"
echo "────────────────────────────────────────────────────────────────"

if [ -d ".git" ]; then
    print_status "pass" "Git repository initialized"
    
    # Check current branch
    CURRENT_BRANCH=$(git branch --show-current)
    print_status "info" "Current branch: $CURRENT_BRANCH"
    
    # Check if there are uncommitted changes
    if git diff-index --quiet HEAD --; then
        print_status "pass" "No uncommitted changes"
    else
        print_status "warn" "Uncommitted changes detected"
        git status --short | head -n 5
    fi
    
    # Check remote
    if git remote -v | grep -q "origin"; then
        REMOTE_URL=$(git remote get-url origin)
        print_status "pass" "Remote configured: $REMOTE_URL"
    else
        print_status "warn" "No remote configured"
    fi
else
    print_status "fail" "Not a Git repository (missing .git/)"
fi

echo ""

# ============================================================================
# 7. BUILD VALIDATION
# ============================================================================

echo "────────────────────────────────────────────────────────────────"
echo "7. BUILD VALIDATION"
echo "────────────────────────────────────────────────────────────────"

if command_exists xcodebuild; then
    print_status "info" "Attempting clean build (this may take 2-3 minutes)..."
    
    # Clean build folder
    xcodebuild clean -quiet -project PorteosIntelligence.xcodeproj -scheme PorteosIntelligence 2>&1 | grep -v "DVTAssertions" | grep -v "CoreSimulatorService" | tail -n 5 || true
    
    # Build project
    if xcodebuild build -quiet -project PorteosIntelligence.xcodeproj -scheme PorteosIntelligence 2>&1 | grep -v "DVTAssertions" | grep -v "CoreSimulatorService" | tail -n 5; then
        print_status "pass" "Build succeeded"
    else
        print_status "fail" "Build failed (see errors above)"
    fi
else
    print_status "fail" "Cannot validate build (xcodebuild not found)"
fi

echo ""

# ============================================================================
# 8. EXTERNAL SERVICES (OPTIONAL)
# ============================================================================

echo "────────────────────────────────────────────────────────────────"
echo "8. EXTERNAL SERVICES (Optional)"
echo "────────────────────────────────────────────────────────────────"

# Check Ollama (optional)
if command_exists ollama; then
    OLLAMA_VERSION=$(ollama --version | awk '{print $3}')
    print_status "pass" "Ollama $OLLAMA_VERSION (for local LLM)"
else
    print_status "info" "Ollama not installed (optional for AI features)"
    echo "         → Install: https://ollama.com/download"
fi

# Check Chrome (for extension)
if [ -d "/Applications/Google Chrome.app" ]; then
    print_status "pass" "Google Chrome installed (for browser extension)"
else
    print_status "info" "Chrome not found (needed for property scraping)"
fi

echo ""

# ============================================================================
# SUMMARY
# ============================================================================

echo "════════════════════════════════════════════════════════════════"
echo "  SETUP VALIDATION SUMMARY"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo -e "✅ Passed:  ${GREEN}$CHECKS_PASSED${NC}"
echo -e "⚠️  Warnings: ${YELLOW}$WARNINGS${NC}"
echo -e "❌ Failed:  ${RED}$CHECKS_FAILED${NC}"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 READY FOR DEVELOPMENT!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Read HANDOVER.md for comprehensive guide"
    echo "  2. Read README.md for project overview"
    echo "  3. Read ARCHITECTURE.md to understand design"
    echo "  4. Open PorteosIntelligence.xcodeproj in Xcode"
    echo "  5. Build (⌘B) and Run (⌘R)"
    echo ""
    exit 0
else
    echo -e "${RED}⚠️  SETUP INCOMPLETE${NC}"
    echo ""
    echo "Fix the failed checks above before proceeding."
    echo "See DEVELOPER_SETUP.md for detailed instructions."
    echo ""
    exit 1
fi
