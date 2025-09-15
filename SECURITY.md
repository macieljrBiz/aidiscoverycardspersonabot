# Security Architecture and Implementation Documentation

## Overview

This document outlines the comprehensive security measures implemented in the AI Discovery Cards Persona Bot application. The security architecture follows defense-in-depth principles with multiple layers of protection across infrastructure, application, and operational security.

## Security Architecture Principles

### 1. Zero Trust Authentication
- **Pure Managed Identity**: No API keys or secrets stored in code or configuration
- **Azure AD Integration**: Authentication through Azure DefaultAzureCredential
- **Principle of Least Privilege**: RBAC role assignments with minimal required permissions

### 2. Defense in Depth
- **Infrastructure Security**: ARM template with secure configurations
- **Application Security**: Input validation, output encoding, error handling
- **Runtime Security**: Content filtering, rate limiting, monitoring

### 3. Secure by Default
- **HTTPS Only**: TLS 1.2 minimum, HTTPS enforcement
- **Content Filtering**: Microsoft.Default RAI policy enabled
- **Secure Headers**: CORS disabled, XSRF protection enabled

## Infrastructure Security Controls

### ARM Template Security Features
The `azuredeploy.json` template implements comprehensive security controls:

#### Azure OpenAI Security
```json
{
  "properties": {
    "disableLocalAuth": true,
    "publicNetworkAccess": "Enabled|Disabled",
    "networkAcls": {
      "defaultAction": "Allow|Deny"
    }
  }
}
```

#### App Service Security Configuration
```json
{
  "siteConfig": {
    "minTlsVersion": "1.2",
    "httpsOnly": true,
    "ftpsState": "Disabled",
    "remoteDebuggingEnabled": false
  }
}
```

#### Content Filtering
```json
{
  "properties": {
    "raiPolicyName": "Microsoft.Default"
  }
}
```

### Security Parameters
- `enableAdvancedSecurity`: Enables Application Insights, logging, and monitoring
- `restrictPublicNetworkAccess`: Controls public access to Azure OpenAI

## Application Security Controls

### Input Validation and Sanitization

#### Functions Implemented
1. **sanitize_input(user_input: str) -> str**
   - Length validation (MAX_MESSAGE_LENGTH = 2000)
   - HTML entity encoding
   - Whitespace normalization
   - Security incident logging

2. **validate_persona_file(filename: str) -> bool**
   - Path traversal prevention
   - Filename pattern validation (ALLOWED_PERSONA_PATTERN)
   - Directory restriction enforcement

#### Security Constants
```python
MAX_MESSAGE_LENGTH = 2000
ALLOWED_PERSONA_PATTERN = r'^[a-zA-Z0-9_-]+\.yaml$'
```

### Error Handling and Logging
- **Safe Error Messages**: Internal error details not exposed to users
- **Security Incident Logging**: Suspicious activities logged for monitoring
- **Graceful Degradation**: Fallback responses for filtered content

### Content Filtering Implementation
Enhanced Azure OpenAI client with:
- Parameter validation and sanitization
- Token limits and rate limiting
- Content filter result logging
- Safe fallback responses

## Monitoring and Alerting

### Application Insights Integration
- **Real-time Monitoring**: Performance and security metrics
- **Log Analytics**: Centralized logging with retention policies
- **Custom Telemetry**: Security event tracking

### Diagnostic Settings
Comprehensive logging categories:
- `AppServiceHTTPLogs`: 30-day retention
- `AppServiceAuditLogs`: 90-day retention (security events)
- `AppServiceIPSecAuditLogs`: 90-day retention (network security)

### Automated Alerts
1. **High CPU Alert**: >80% for 15 minutes
2. **High Memory Alert**: >85% for 15 minutes  
3. **HTTP Error Alert**: >10 5xx errors in 15 minutes

## Operational Security

### Managed Identity Configuration
```python
credential = DefaultAzureCredential(
    exclude_interactive_browser_credential=True,
    exclude_shared_token_cache_credential=True,
    exclude_visual_studio_code_credential=False,
    exclude_cli_credential=False,
    exclude_environment_credential=False,
    exclude_managed_identity_credential=False
)
```

### RBAC Role Assignment
- **Role**: Cognitive Services OpenAI User (5e0bd9bd-7b93-4f28-af87-19fc36ad61bd)
- **Scope**: Azure OpenAI resource only
- **Principal**: App Service System Assigned Identity

### Environment Variables Security
Required secure variables:
- `AZURE_OPENAI_ENDPOINT`: Service endpoint URL
- `AZURE_OPENAI_DEPLOYMENT_NAME`: Model deployment name
- `AZURE_OPENAI_API_VERSION`: API version

## Security Best Practices Implemented

### 1. Authentication and Authorization
✅ Managed Identity for Azure services  
✅ No API keys in code or configuration  
✅ RBAC with least privilege  
✅ Disabled local authentication  

### 2. Data Protection
✅ HTTPS enforcement with TLS 1.2 minimum  
✅ Input validation and output encoding  
✅ Content filtering with Microsoft policies  
✅ Secure error handling  

### 3. Network Security
✅ HTTPS-only communication  
✅ Disabled FTP/FTPS  
✅ Optional network access restrictions  
✅ CORS security controls  

### 4. Monitoring and Logging
✅ Comprehensive audit logging  
✅ Security event monitoring  
✅ Automated alerting  
✅ Log retention policies  

### 5. Application Security
✅ Input validation functions  
✅ Path traversal prevention  
✅ HTML encoding  
✅ Rate limiting  

## Security Configuration Checklist

### Pre-Deployment
- [ ] Review ARM template security settings
- [ ] Validate input validation functions
- [ ] Confirm content filtering configuration
- [ ] Test Managed Identity authentication

### Post-Deployment
- [ ] Verify HTTPS enforcement
- [ ] Confirm Application Insights logging
- [ ] Test security alerts
- [ ] Validate content filtering

### Ongoing Operations
- [ ] Monitor security logs regularly
- [ ] Review alert notifications
- [ ] Update security configurations as needed
- [ ] Conduct periodic security reviews

## Incident Response Procedures

### Security Event Detection
1. **Automated Alerts**: Monitor Application Insights alerts
2. **Log Analysis**: Review audit logs for suspicious patterns
3. **User Reports**: Process security-related user feedback

### Response Actions
1. **Immediate**: Isolate affected resources if needed
2. **Investigation**: Analyze logs and determine impact
3. **Remediation**: Apply security patches or configuration changes
4. **Documentation**: Record incident details and lessons learned

### Escalation Matrix
- **Level 1**: Development team for application issues
- **Level 2**: Security team for security incidents
- **Level 3**: Azure support for infrastructure issues

## Compliance and Governance

### Security Standards Alignment
- **Azure Security Baseline**: Infrastructure configurations
- **OWASP Guidelines**: Application security practices
- **Microsoft Security Development Lifecycle**: Development processes

### Regular Security Reviews
- **Monthly**: Review security logs and alerts
- **Quarterly**: Update security configurations
- **Annually**: Comprehensive security assessment

## Contact Information

For security-related questions or incidents:
- **Development Team**: vicentem@microsoft.com
- **Repository**: https://github.com/macieljrBiz/aidiscoverycardspersonabot

---

*This document should be reviewed and updated regularly to reflect security configuration changes and emerging threats.*