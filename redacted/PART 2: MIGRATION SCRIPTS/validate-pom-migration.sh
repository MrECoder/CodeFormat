#!/bin/bash
#
# validate-pom-migration.sh
#
# Validates that POM files have been correctly migrated
#

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

validate_pom() {
    local pom_file=$1
    local errors=0
    
    echo "Validating: ${pom_file}"
    
    # Check for CI-friendly version
    if grep -q '\${revision}\${changelist}' "${pom_file}"; then
        print_result 0 "Uses CI-friendly version syntax"
    else
        print_result 1 "Missing CI-friendly version syntax"
        ((errors++))
    fi
    
    # Check for hardcoded user versions
    if grep -q 'user\.name' "${pom_file}"; then
        print_result 1 "Still contains hardcoded user version"
        ((errors++))
    else
        print_result 0 "No hardcoded user versions found"
    fi
    
    # Check for revision property
    if grep -q '<revision>' "${pom_file}"; then
        print_result 0 "Has revision property"
    else
        print_result 1 "Missing revision property"
        ((errors++))
    fi
    
    # Check for changelist property
    if grep -q '<changelist>' "${pom_file}"; then
        print_result 0 "Has changelist property"
    else
        print_result 1 "Missing changelist property"
        ((errors++))
    fi
    
    # Check for flatten plugin (should be in most POMs)
    if grep -q 'flatten-maven-plugin' "${pom_file}"; then
        print_result 0 "Has flatten-maven-plugin"
    else
        print_result 1 "Missing flatten-maven-plugin (may need manual addition)"
    fi
    
    echo "---"
    return $errors
}

# Validate all POMs
total_errors=0

validate_pom "./bom/pom.xml" || ((total_errors+=$?))
validate_pom "./parent/pom.xml" || ((total_errors+=$?))
validate_pom "./aggregator/pom.xml" || ((total_errors+=$?))
validate_pom "./code-style/pom.xml" || ((total_errors+=$?))
validate_pom "../common-java-components/pom.xml" || ((total_errors+=$?))
validate_pom "../common-rabbitmq-components/pom.xml" || ((total_errors+=$?))
validate_pom "../common-notification-service/pom.xml" || ((total_errors+=$?))
validate_pom "../application-catalogue-service/pom.xml" || ((total_errors+=$?))
validate_pom "../application-instance-access-service/pom.xml" || ((total_errors+=$?))

if [ $total_errors -eq 0 ]; then
    echo -e "${GREEN}All validations passed!${NC}"
    exit 0
else
    echo -e "${RED}Validation failed with ${total_errors} errors${NC}"
    exit 1
fi
