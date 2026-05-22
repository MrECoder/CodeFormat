#!/bin/bash
#
# migrate-to-ci-friendly-versions.sh
# 
# Automates migration of Maven POMs from hardcoded versions to CI-friendly versions
# Usage: ./migrate-to-ci-friendly-versions.sh [--dry-run]
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DRY_RUN=false
BACKUP_DIR="./pom-backups-$(date +%Y%m%d-%H%M%S)"
BASE_VERSION="0.0.1"
DEFAULT_CHANGELIST="-SNAPSHOT"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--dry-run]"
            exit 1
            ;;
    esac
done

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to backup POM file
backup_pom() {
    local pom_file=$1
    local backup_path="${BACKUP_DIR}/$(dirname ${pom_file})"
    
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "${backup_path}"
        cp "${pom_file}" "${backup_path}/"
        print_info "Backed up: ${pom_file}"
    fi
}

# Function to update POM file
update_pom() {
    local pom_file=$1
    local artifact_type=$2  # bom, parent, child, aggregator, standalone
    
    print_info "Processing: ${pom_file} (type: ${artifact_type})"
    
    if [ ! -f "${pom_file}" ]; then
        print_error "File not found: ${pom_file}"
        return 1
    fi
    
    # Backup original
    backup_pom "${pom_file}"
    
    if [ "$DRY_RUN" = true ]; then
        print_warning "DRY RUN: Would update ${pom_file}"
        return 0
    fi
    
    # Create temporary file
    local tmp_file="${pom_file}.tmp"
    
    case ${artifact_type} in
        bom)
            update_bom_pom "${pom_file}" "${tmp_file}"
            ;;
        parent)
            update_parent_pom "${pom_file}" "${tmp_file}"
            ;;
        aggregator)
            update_aggregator_pom "${pom_file}" "${tmp_file}"
            ;;
        child)
            update_child_pom "${pom_file}" "${tmp_file}"
            ;;
        standalone)
            update_standalone_pom "${pom_file}" "${tmp_file}"
            ;;
        *)
            print_error "Unknown artifact type: ${artifact_type}"
            return 1
            ;;
    esac
    
    # Replace original with updated
    mv "${tmp_file}" "${pom_file}"
    print_success "Updated: ${pom_file}"
}

# Update BOM POM
update_bom_pom() {
    local input_file=$1
    local output_file=$2
    
    # Use sed to perform replacements
    sed -E '
        # Replace version tag
        s|<version>[^<]*-user\.[^<]*</version>|<version>${revision}${changelist}</version>|g
        s|<version>0\.0\.1</version>|<version>${revision}${changelist}</version>|g
        
        # Add properties block if after <packaging>pom</packaging>
        /<packaging>pom<\/packaging>/a\
\
    <!-- ============================================================ -->\
    <!-- CI-Friendly Version Properties                               -->\
    <!-- ============================================================ -->\
    <properties>\
        <revision>0.0.1</revision>\
        <changelist>-SNAPSHOT</changelist>\
\
        <!-- Internal component versions -->\
        <code-style.version>${revision}${changelist}</code-style.version>\
        <common-java-components.version>${revision}${changelist}</common-java-components.version>\
        <common-rabbitmq-components.version>${revision}${changelist}</common-rabbitmq-components.version>\
        <common-notification-service.version>${revision}${changelist}</common-notification-service.version>\
    </properties>
        
        # Remove old properties block if exists
        /<properties>/,/<\/properties>/d
        
        # Replace hardcoded versions in dependencies
        s|<version>0\.0\.1-user\.[^<]*</version>|<!-- Version managed by property -->|g
    ' "${input_file}" > "${output_file}"
    
    # Add flatten plugin if not present
    if ! grep -q "flatten-maven-plugin" "${output_file}"; then
        add_flatten_plugin_to_bom "${output_file}"
    fi
}

# Update Parent POM
update_parent_pom() {
    local input_file=$1
    local output_file=$2
    
    sed -E '
        # Replace version
        s|<version>[^<]*-user\.[^<]*</version>|<version>${revision}${changelist}</version>|g
        s|<version>0\.0\.1</version>|<version>${revision}${changelist}</version>|g
        
        # Update properties
        /<java\.version>/i\
        <revision>0.0.1</revision>\
        <changelist>-SNAPSHOT</changelist>
        
        # Replace code-style version in spotless plugin
        s|<version>0\.0\.1-user\.[^<]*</version>(\s*<!-- .*code-style.* -->)?|<version>${code-style.version}</version>|g
    ' "${input_file}" > "${output_file}"
    
    # Add flatten plugin if not present
    if ! grep -q "flatten-maven-plugin" "${output_file}"; then
        add_flatten_plugin_to_parent "${output_file}"
    fi
}

# Update Aggregator POM
update_aggregator_pom() {
    local input_file=$1
    local output_file=$2
    
    sed -E '
        # Replace version
        s|<version>[^<]*</version>(\s*<!-- .*version.* -->)?|<version>${revision}${changelist}</version>|g
        
        # Add properties after packaging
        /<packaging>pom<\/packaging>/a\
\
    <properties>\
        <revision>0.0.1</revision>\
        <changelist>-SNAPSHOT</changelist>\
    </properties>
    ' "${input_file}" > "${output_file}"
}

# Update Child POM (common components and microservices)
update_child_pom() {
    local input_file=$1
    local output_file=$2
    
    sed -E '
        # Update parent version
        /<parent>/,/<\/parent>/ {
            s|<version>[^<]*-user\.[^<]*</version>|<version>${revision}${changelist}</version>|g
            s|<version>0\.0\.1</version>|<version>${revision}${changelist}</version>|g
        }
        
        # Remove project version (inherited from parent)
        /<artifactId>[^<]*<\/artifactId>/,/<packaging>/ {
            /<version>/d
        }
        
        # Add properties block after </parent>
        /<\/parent>/a\
\
    <properties>\
        <revision>0.0.1</revision>\
        <changelist>-SNAPSHOT</changelist>\
    </properties>
        
        # Remove version from internal dependencies
        /<groupId>redacted\.group\.id<\/groupId>/,/<\/dependency>/ {
            /<version>0\.0\.1-user\.[^<]*<\/version>/d
            /<version>${.*\.version}<\/version>/d
        }
        
        # Remove hardcoded versions from spotless code-style dependency
        /<artifactId>code-style<\/artifactId>/,/<\/dependency>/ {
            s|<version>0\.0\.1-user\.[^<]*</version>|<!-- Version from BOM -->|g
        }
    ' "${input_file}" > "${output_file}"
    
    # Add flatten plugin if not present
    if ! grep -q "flatten-maven-plugin" "${output_file}"; then
        add_flatten_plugin_to_child "${output_file}"
    fi
}

# Update Standalone POM (code-style)
update_standalone_pom() {
    local input_file=$1
    local output_file=$2
    
    sed -E '
        # Replace version
        s|<version>0\.0\.1</version>|<version>${revision}${changelist}</version>|g
        
        # Add properties
        /<packaging>jar<\/packaging>/a\
\
    <properties>\
        <revision>0.0.1</revision>\
        <changelist>-SNAPSHOT</changelist>\
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>\
    </properties>
    ' "${input_file}" > "${output_file}"
    
    if ! grep -q "flatten-maven-plugin" "${output_file}"; then
        add_flatten_plugin_to_standalone "${output_file}"
    fi
}

# Helper functions to add flatten plugin
add_flatten_plugin_to_bom() {
    local pom_file=$1
    # Implementation would use xmlstarlet or similar
    # For simplicity, manual addition recommended
    print_warning "Please manually add flatten-maven-plugin to ${pom_file}"
}

add_flatten_plugin_to_parent() {
    local pom_file=$1
    print_warning "Please manually add flatten-maven-plugin to ${pom_file}"
}

add_flatten_plugin_to_child() {
    local pom_file=$1
    print_warning "Please manually add flatten-maven-plugin to ${pom_file}"
}

add_flatten_plugin_to_standalone() {
    local pom_file=$1
    print_warning "Please manually add flatten-maven-plugin to ${pom_file}"
}

# Main execution
main() {
    print_info "Starting POM migration to CI-friendly versions"
    print_info "Base version: ${BASE_VERSION}"
    print_info "Default changelist: ${DEFAULT_CHANGELIST}"
    
    if [ "$DRY_RUN" = true ]; then
        print_warning "Running in DRY RUN mode - no files will be modified"
    else
        print_info "Creating backup directory: ${BACKUP_DIR}"
        mkdir -p "${BACKUP_DIR}"
    fi
    
    # Update parent-pom repo POMs
    print_info "=== Processing parent-pom repository ==="
    
    update_pom "./bom/pom.xml" "bom"
    update_pom "./parent/pom.xml" "parent"
    update_pom "./aggregator/pom.xml" "aggregator"
    update_pom "./code-style/pom.xml" "standalone"
    
    # Update component POMs
    print_info "=== Processing component repositories ==="
    
    update_pom "../common-java-components/pom.xml" "child"
    update_pom "../common-rabbitmq-components/pom.xml" "child"
    update_pom "../common-notification-service/pom.xml" "child"
    
    # Update microservice POMs
    print_info "=== Processing microservice repositories ==="
    
    update_pom "../application-catalogue-service/pom.xml" "child"
    update_pom "../application-instance-access-service/pom.xml" "child"
    
    print_success "Migration complete!"
    
    if [ "$DRY_RUN" = false ]; then
        print_info "Backups stored in: ${BACKUP_DIR}"
        print_warning "IMPORTANT: Review changes before committing"
        print_warning "Test with: mvn clean install -Drevision=0.0.1 -Dchangelist=-SNAPSHOT"
    fi
}

# Run main
main
