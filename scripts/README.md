# OpsPilot Scripts

This directory contains utility scripts for managing and maintaining the OpsPilot project.

## Scripts Overview

### Bootstrap Script

#### `bootstrap.sh`
**Purpose**: Initial project setup and environment configuration

**Functionality**:
- Installs required dependencies and tools
- Sets up development environment
- Configures project structure
- Initializes database connections
- Validates system requirements

**Usage**:
```bash
./scripts/bootstrap.sh
```

**Prerequisites**:
- Bash shell
- Internet connection for downloading dependencies
- Appropriate permissions for installing system packages

**Features**:
- Dependency checking and installation
- Environment validation
- Project initialization
- Configuration file generation

### Health Check Script

#### `healthcheck.sh`
**Purpose**: System health monitoring and validation

**Functionality**:
- Checks database connectivity
- Validates API endpoints
- Monitors system resources
- Reports service status
- Performs dependency verification

**Usage**:
```bash
./scripts/healthcheck.sh
```

**Output**:
- Service status report
- Database connection status
- Resource utilization metrics
- Error reporting and diagnostics

**Integration**:
- Can be used with monitoring systems
- Supports CI/CD pipeline integration
- Provides JSON output for automated processing

## Script Dependencies

### Required Tools
- `curl` - For API endpoint testing
- `psql` - For PostgreSQL database operations
- `go` - For Go application management
- `node` - For JavaScript/Node.js operations (if applicable)

### Optional Tools
- `jq` - For JSON parsing and formatting
- `docker` - For containerized environments
- `kubectl` - For Kubernetes deployments

## Usage Examples

### Development Environment Setup
```bash
# Run bootstrap script for initial setup
./scripts/bootstrap.sh

# Verify system health after setup
./scripts/healthcheck.sh
```

### CI/CD Integration
```bash
# In your CI pipeline
./scripts/bootstrap.sh
./scripts/healthcheck.sh --json-output
```

### Monitoring Integration
```bash
# For automated monitoring
./scripts/healthcheck.sh --format=json | jq '.services.api.status'
```

## Configuration

### Environment Variables
Scripts respect the following environment variables:

- `ENVIRONMENT` - Target environment (development, staging, production)
- `VERBOSE` - Enable verbose output (true/false)
- `TIMEOUT` - Timeout for operations in seconds
- `LOG_LEVEL` - Logging level (debug, info, warn, error)

### Configuration Files
- `.env` - Environment-specific configuration
- `scripts/config.json` - Script-specific settings
- `scripts/dependencies.json` - Dependency requirements

## Error Handling

### Exit Codes
- `0` - Success
- `1` - General error
- `2` - Missing dependencies
- `3` - Configuration error
- `4` - Network connectivity issues
- `5` - Database connection failure

### Logging
Scripts provide detailed logging with the following levels:
- **DEBUG**: Detailed execution information
- **INFO**: General operation information
- **WARN**: Non-critical issues
- **ERROR**: Critical failures that halt execution

## Maintenance

### Regular Tasks
1. **Update Dependencies**: Regularly update script dependencies
2. **Test Scripts**: Validate scripts work with current system configuration
3. **Review Logs**: Monitor script execution logs for issues
4. **Update Documentation**: Keep this README updated with changes

### Troubleshooting

#### Common Issues

**Permission Denied**
```bash
chmod +x scripts/*.sh
```

**Missing Dependencies**
```bash
# Install missing tools
sudo apt-get install curl jq docker
```

**Environment Variables Not Set**
```bash
# Source environment file
source .env
```

#### Debug Mode
Enable debug mode for detailed troubleshooting:
```bash
export VERBOSE=true
./scripts/bootstrap.sh
```

## Security Considerations

### Best Practices
- Never commit sensitive information to scripts
- Use environment variables for secrets
- Validate all inputs and outputs
- Run scripts with minimal required permissions
- Regularly audit script security

### File Permissions
- Scripts should be executable only by authorized users
- Configuration files should not be world-readable
- Log files should have appropriate access controls

## Contributing

### Adding New Scripts
1. Create script in `scripts/` directory
2. Add executable permissions: `chmod +x script_name.sh`
3. Update this README with script documentation
4. Add error handling and logging
5. Include usage examples

### Script Standards
- Use bash shebang: `#!/bin/bash`
- Include error handling with `set -e`
- Add help function with `-h` flag
- Use consistent naming convention
- Include version and author information

## Version History

### v1.0.0
- Initial script collection
- Bootstrap and health check functionality
- Basic error handling and logging

## Support

For issues with scripts:
1. Check this README for troubleshooting steps
2. Review script logs for error details
3. Verify environment configuration
4. Report issues with full error output and system information

## License

Scripts are licensed under the same license as the main project.