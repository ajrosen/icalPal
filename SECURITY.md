# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 3.10.x  | :white_check_mark: |
| < 3.10  | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in icalPal, please report it responsibly:

### Private Disclosure

1. **Do not** create a public GitHub issue for security vulnerabilities
2. Email security reports to: [security@corp.mlfs.org](mailto:security@corp.mlfs.org)
3. Include "SECURITY" in the subject line
4. Provide detailed information about the vulnerability

### What to Include

- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact assessment
- Suggested fix (if available)
- Your contact information

### Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Resolution**: Varies based on complexity

### Disclosure Process

1. We will acknowledge receipt of your report
2. We will investigate and validate the vulnerability
3. We will develop and test a fix
4. We will coordinate disclosure timing with you
5. We will credit you in the security advisory (unless you prefer anonymity)

## Security Considerations

### Database Access

icalPal requires access to macOS Calendar and Reminders databases. Users should:

- Only run icalPal from trusted sources
- Be aware that "Full Disk Access" permissions are required
- Regularly review applications with database access

### Data Handling

- icalPal processes local calendar data only
- No data is transmitted to external services
- Database files should be protected with appropriate file permissions

## Contact

For security-related questions: [security@corp.mlfs.org](mailto:security@corp.mlfs.org)
