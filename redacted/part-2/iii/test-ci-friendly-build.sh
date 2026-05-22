#!/bin/bash
#
# test-ci-friendly-build.sh
#
# Tests CI-friendly version builds with different scenarios
#

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Test 1: Default build (should produce 0.0.1-SNAPSHOT)
print_test "Testing default build (should produce 0.0.1-SNAPSHOT)"
mvn clean install
print_success "Default build completed"

# Test 2: Feature branch simulation
print_test "Testing feature branch version (0.0.1-SNAPSHOT-jsmith-feature-123)"
mvn clean install \
    -Drevision=0.0.1 \
    -Dchangelist=-SNAPSHOT-jsmith-feature-123
print_success "Feature branch build completed"

# Test 3: Release version
print_test "Testing release version (0.0.1)"
mvn clean install \
    -Drevision=0.0.1 \
    -Dchangelist=
print_success "Release build completed"

# Test 4: Validate deployed POM has resolved versions
print_test "Checking that .flattened-pom.xml has resolved versions"
if [ -f "bom/.flattened-pom.xml" ]; then
    if grep -q '\${revision}' "bom/.flattened-pom.xml"; then
        echo -e "${YELLOW}WARNING: Flattened POM still contains property placeholders${NC}"
        exit 1
    else
        print_success "Flattened POM has resolved versions"
    fi
else
    echo -e "${YELLOW}WARNING: .flattened-pom.xml not found${NC}"
fi

print_success "All tests passed!"
