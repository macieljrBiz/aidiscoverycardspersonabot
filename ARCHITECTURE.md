# AI Discovery Cards Persona Bot - Architecture Documentation

## Overview

The AI Discovery Cards Persona Bot is a secure, cloud-native application built on Azure that enables interactive conversations with AI-powered customer personas. The architecture implements enterprise-grade security, scalability, and monitoring capabilities while maintaining simplicity and ease of deployment.

## System Architecture

### High-Level Architecture

```mermaid
graph TB
    subgraph "User Layer"
        U[User Browser]
    end
    
    subgraph "Azure Cloud"
        subgraph "App Service"
            WA[Web App<br/>Streamlit Frontend]
            PB[Persona Bot<br/>Backend Logic]
        end
        
        subgraph "AI Services"
            AOI[Azure OpenAI<br/>GPT-4o-mini]
            CF[Content Filtering<br/>Microsoft.Default RAI]
        end
        
        subgraph "Storage & Config"
            PC[Persona Configs<br/>YAML Files]
            ENV[Environment Variables<br/>Secure Configuration]
        end
        
        subgraph "Security & Identity"
            MI[Managed Identity<br/>System Assigned]
            RBAC[RBAC Roles<br/>OpenAI User]
        end
        
        subgraph "Monitoring & Logging"
            AI[Application Insights<br/>Telemetry & Metrics]
            LA[Log Analytics<br/>Centralized Logging]
            AL[Metric Alerts<br/>CPU, Memory, Errors]
        end
    end
    
    U -->|HTTPS Only| WA
    WA --> PB
    PB -->|Managed Identity| AOI
    AOI --> CF
    PB --> PC
    WA --> ENV
    
    WA -.->|Logs & Metrics| AI
    WA -.->|Diagnostic Logs| LA
    AI -.->|Triggers| AL
    
    MI -->|Authenticates| AOI
    RBAC -->|Authorizes| AOI
    
    style U fill:#e1f5fe
    style WA fill:#f3e5f5
    style AOI fill:#e8f5e8
    style MI fill:#fff3e0
    style AI fill:#fce4ec
```

### Component Architecture

```mermaid
graph LR
    subgraph "Frontend Layer"
        ST[Streamlit App]
        UI[Chat Interface]
        PS[Persona Selector]
        SC[Security Controls]
    end
    
    subgraph "Business Logic Layer"
        PB[PersonaBot]
        PL[PersonaLoader]
        PrB[PromptBuilder]
        AOC[AzureOpenAIClient]
    end
    
    subgraph "Security Layer"
        IV[Input Validation]
        SAN[Sanitization]
        VF[File Validation]
        EH[Error Handling]
    end
    
    subgraph "Integration Layer"
        MI[Managed Identity]
        CR[Credential Provider]
        API[Azure OpenAI API]
    end
    
    ST --> UI
    ST --> PS
    ST --> SC
    
    UI --> PB
    PS --> PL
    SC --> IV
    
    PB --> PrB
    PB --> AOC
    PL --> VF
    
    IV --> SAN
    AOC --> EH
    
    AOC --> MI
    MI --> CR
    CR --> API
    
    style ST fill:#e3f2fd
    style PB fill:#f1f8e9
    style IV fill:#fff8e1
    style MI fill:#fce4ec
```

## Data Flow Architecture

### User Interaction Flow

```mermaid
sequenceDiagram
    participant U as User
    participant ST as Streamlit App
    participant PB as PersonaBot
    participant AOI as Azure OpenAI
    participant CF as Content Filter
    participant AI as App Insights
    
    U->>ST: Select persona & send message
    ST->>ST: Validate & sanitize input
    ST->>PB: Process user request
    PB->>PB: Load persona config
    PB->>PB: Build system prompt
    
    PB->>AOI: Send chat completion request
    AOI->>CF: Apply content filtering
    CF->>AOI: Return filtered response
    AOI->>PB: Return AI response
    
    PB->>ST: Return formatted response
    ST->>U: Display chat response
    
    ST-->>AI: Log interaction metrics
    PB-->>AI: Log performance data
    AOI-->>AI: Log usage statistics
    
    Note over CF: Microsoft.Default RAI Policy
    Note over AI: Security & Performance Monitoring
```

### Authentication Flow

```mermaid
sequenceDiagram
    participant AS as App Service
    participant MI as Managed Identity
    participant AAD as Azure AD
    participant AOI as Azure OpenAI
    
    AS->>MI: Request token for OpenAI
    MI->>AAD: Authenticate with system identity
    AAD->>AAD: Validate identity & permissions
    AAD->>MI: Return access token
    MI->>AS: Provide token
    AS->>AOI: API call with bearer token
    AOI->>AOI: Validate token & RBAC
    AOI->>AS: Return API response
    
    Note over MI: System Assigned Identity
    Note over AAD: Zero secrets in code
    Note over AOI: Cognitive Services OpenAI User Role
```

## Security Architecture

### Security Layers

```mermaid
graph TD
    subgraph "Network Security"
        HTTPS[HTTPS Only<br/>TLS 1.2+]
        CORS[CORS Disabled]
        FTP[FTP Disabled]
    end
    
    subgraph "Application Security"
        INPUT[Input Validation<br/>Length & Pattern]
        ESCAPE[HTML Escaping<br/>XSS Prevention]
        PATH[Path Traversal<br/>Protection]
        ERROR[Safe Error<br/>Handling]
    end
    
    subgraph "Authentication Security"
        NOAPIKEY[No API Keys<br/>Zero Secrets]
        MANAGED[Managed Identity<br/>Azure AD]
        RBAC[Least Privilege<br/>RBAC Roles]
    end
    
    subgraph "Content Security"
        FILTER[Content Filtering<br/>Microsoft RAI]
        RATE[Rate Limiting<br/>Token Controls]
        AUDIT[Audit Logging<br/>Security Events]
    end
    
    subgraph "Infrastructure Security"
        SECURE[Secure Defaults<br/>ARM Template]
        MONITOR[Real-time<br/>Monitoring]
        ALERT[Automated<br/>Alerting]
    end
    
    HTTPS --> INPUT
    INPUT --> NOAPIKEY
    NOAPIKEY --> FILTER
    FILTER --> SECURE
    
    style HTTPS fill:#ffebee
    style INPUT fill:#e8f5e8
    style NOAPIKEY fill:#fff3e0
    style FILTER fill:#e3f2fd
    style SECURE fill:#f3e5f5
```

### Security Controls Matrix

```mermaid
graph LR
    subgraph "Preventive Controls"
        P1[Input Validation]
        P2[Content Filtering]
        P3[HTTPS Enforcement]
        P4[Access Controls]
    end
    
    subgraph "Detective Controls"
        D1[Application Insights]
        D2[Audit Logging]
        D3[Metric Alerts]
        D4[Security Monitoring]
    end
    
    subgraph "Corrective Controls"
        C1[Error Handling]
        C2[Graceful Degradation]
        C3[Incident Response]
        C4[Alert Actions]
    end
    
    P1 --> D1
    P2 --> D2
    P3 --> D3
    P4 --> D4
    
    D1 --> C1
    D2 --> C2
    D3 --> C3
    D4 --> C4
    
    style P1 fill:#e8f5e8
    style D1 fill:#fff3e0
    style C1 fill:#ffebee
```

## Deployment Architecture

### Infrastructure Components

```mermaid
graph TB
    subgraph "Resource Group"
        subgraph "Compute"
            ASP[App Service Plan<br/>Linux B1]
            AS[App Service<br/>Python 3.11]
        end
        
        subgraph "AI & Cognitive"
            AOAI[Azure OpenAI<br/>GPT-4o-mini]
            DEP[Model Deployment<br/>Standard Scale]
        end
        
        subgraph "Monitoring"
            AI[Application Insights<br/>Web Analytics]
            LA[Log Analytics<br/>Workspace]
        end
        
        subgraph "Security"
            MI[System Managed<br/>Identity]
            RBAC[Role Assignment<br/>OpenAI User]
        end
        
        subgraph "Networking"
            TLS[TLS 1.2+]
            HTTPS[HTTPS Only]
        end
    end
    
    AS --> ASP
    AS --> MI
    AS --> AI
    AI --> LA
    
    AOAI --> DEP
    MI --> RBAC
    RBAC --> AOAI
    
    AS --> TLS
    AS --> HTTPS
    
    style AS fill:#e3f2fd
    style AOAI fill:#e8f5e8
    style MI fill:#fff3e0
    style AI fill:#fce4ec
```

### Deployment Pipeline

```mermaid
graph LR
    subgraph "Source Control"
        GH[GitHub Repository<br/>macieljrBiz/aidiscoverycardspersonabot]
    end
    
    subgraph "Deployment"
        ARM[ARM Template<br/>azuredeploy.json]
        DAB[Deploy to Azure<br/>Button]
        AZ[Azure Portal<br/>Deployment]
    end
    
    subgraph "Configuration"
        ENV[Environment<br/>Variables]
        SEC[Security<br/>Settings]
        MON[Monitoring<br/>Setup]
    end
    
    subgraph "Validation"
        HEALTH[Health Check<br/>Endpoint]
        TEST[Security<br/>Testing]
        VERIFY[Deployment<br/>Verification]
    end
    
    GH --> ARM
    ARM --> DAB
    DAB --> AZ
    
    AZ --> ENV
    AZ --> SEC
    AZ --> MON
    
    MON --> HEALTH
    SEC --> TEST
    ENV --> VERIFY
    
    style GH fill:#f0f0f0
    style ARM fill:#e3f2fd
    style AZ fill:#e8f5e8
    style HEALTH fill:#fff3e0
```

## Technology Stack

### Frontend Stack

```mermaid
mindmap
  root((Frontend))
    Streamlit
      Python 3.11
      Web Interface
      Chat Components
      Real-time Updates
    Security
      Input Validation
      HTML Escaping
      XSRF Protection
      CORS Controls
    UI Components
      Chat Interface
      Persona Selector
      Configuration Panel
      Status Indicators
```

### Backend Stack

```mermaid
mindmap
  root((Backend))
    Python
      Streamlit Framework
      Azure SDK
      OpenAI Client
      YAML Processing
    Azure Services
      App Service
      Azure OpenAI
      Managed Identity
      Application Insights
    Security
      Managed Identity
      Content Filtering
      Rate Limiting
      Audit Logging
```

## Data Architecture

### Data Flow Patterns

```mermaid
flowchart TD
    subgraph "User Input"
        UI[User Message]
        VAL[Validation]
        SAN[Sanitization]
    end
    
    subgraph "Persona Processing"
        PC[Persona Config]
        SYS[System Prompt]
        CTX[Context Building]
    end
    
    subgraph "AI Processing"
        REQ[API Request]
        FILT[Content Filter]
        RESP[AI Response]
    end
    
    subgraph "Output Processing"
        FORMAT[Response Format]
        SAFE[Safety Check]
        DISPLAY[Display Output]
    end
    
    UI --> VAL
    VAL --> SAN
    SAN --> PC
    
    PC --> SYS
    SYS --> CTX
    CTX --> REQ
    
    REQ --> FILT
    FILT --> RESP
    RESP --> FORMAT
    
    FORMAT --> SAFE
    SAFE --> DISPLAY
    
    style UI fill:#e1f5fe
    style FILT fill:#e8f5e8
    style SAFE fill:#fff3e0
    style DISPLAY fill:#f3e5f5
```

### Configuration Management

```mermaid
graph TB
    subgraph "Configuration Sources"
        YAML[Persona YAML<br/>Files]
        ENV[Environment<br/>Variables]
        ARM[ARM Template<br/>Parameters]
    end
    
    subgraph "Configuration Processing"
        LOAD[Config Loader]
        VALID[Validation]
        CACHE[Runtime Cache]
    end
    
    subgraph "Application Usage"
        PROMPT[Prompt Building]
        BEHAV[Behavior Control]
        RESP[Response Formatting]
    end
    
    YAML --> LOAD
    ENV --> LOAD
    ARM --> LOAD
    
    LOAD --> VALID
    VALID --> CACHE
    
    CACHE --> PROMPT
    CACHE --> BEHAV
    CACHE --> RESP
    
    style YAML fill:#e8f5e8
    style ENV fill:#fff3e0
    style CACHE fill:#e3f2fd
```

## Monitoring Architecture

### Observability Stack

```mermaid
graph TB
    subgraph "Data Collection"
        APP[Application<br/>Telemetry]
        DIAG[Diagnostic<br/>Logs]
        METRIC[Performance<br/>Metrics]
    end
    
    subgraph "Data Storage"
        AI[Application<br/>Insights]
        LA[Log Analytics<br/>Workspace]
        RETENTION[Data Retention<br/>Policies]
    end
    
    subgraph "Analysis & Alerting"
        QUERY[KQL Queries]
        DASH[Dashboards]
        ALERT[Metric Alerts]
    end
    
    subgraph "Response"
        NOTIFY[Notifications]
        ACTION[Automated<br/>Actions]
        INCIDENT[Incident<br/>Management]
    end
    
    APP --> AI
    DIAG --> LA
    METRIC --> AI
    
    AI --> QUERY
    LA --> QUERY
    AI --> RETENTION
    
    QUERY --> DASH
    QUERY --> ALERT
    
    ALERT --> NOTIFY
    ALERT --> ACTION
    NOTIFY --> INCIDENT
    
    style APP fill:#e3f2fd
    style AI fill:#e8f5e8
    style ALERT fill:#fff3e0
    style INCIDENT fill:#ffebee
```

### Alert Configuration

```mermaid
graph LR
    subgraph "Performance Alerts"
        CPU[High CPU<br/>>80% for 15min]
        MEM[High Memory<br/>>85% for 15min]
        RESP[Response Time<br/>>5s average]
    end
    
    subgraph "Error Alerts"
        HTTP[HTTP 5xx Errors<br/>>10 in 15min]
        APP_ERR[Application<br/>Exceptions]
        AUTH[Authentication<br/>Failures]
    end
    
    subgraph "Security Alerts"
        SEC[Security Events<br/>Suspicious Activity]
        FILTER[Content Filter<br/>Violations]
        ACCESS[Unauthorized<br/>Access Attempts]
    end
    
    subgraph "Business Alerts"
        USAGE[High Usage<br/>Rate Limits]
        COST[Cost<br/>Thresholds]
        AVAILABILITY[Service<br/>Availability]
    end
    
    CPU --> NOTIFY[Notification<br/>Channels]
    HTTP --> NOTIFY
    SEC --> NOTIFY
    USAGE --> NOTIFY
    
    style CPU fill:#fff3e0
    style HTTP fill:#ffebee
    style SEC fill:#fce4ec
    style USAGE fill:#e8f5e8
```

## Performance Architecture

### Scalability Considerations

```mermaid
graph TB
    subgraph "Application Tier"
        SCALE[App Service<br/>Auto-scaling]
        CACHE[Session<br/>Management]
        CONN[Connection<br/>Pooling]
    end
    
    subgraph "AI Service Tier"
        TOKEN[Token Rate<br/>Limiting]
        QUEUE[Request<br/>Queuing]
        RETRY[Retry<br/>Logic]
    end
    
    subgraph "Data Tier"
        CONFIG[Config<br/>Caching]
        PERSONA[Persona<br/>Loading]
        HISTORY[Chat History<br/>Management]
    end
    
    subgraph "Monitoring Tier"
        METRICS[Performance<br/>Metrics]
        THRESH[Threshold<br/>Monitoring]
        AUTO[Auto-scaling<br/>Triggers]
    end
    
    SCALE --> TOKEN
    CACHE --> QUEUE
    CONN --> RETRY
    
    TOKEN --> CONFIG
    QUEUE --> PERSONA
    RETRY --> HISTORY
    
    CONFIG --> METRICS
    PERSONA --> THRESH
    HISTORY --> AUTO
    
    AUTO --> SCALE
    
    style SCALE fill:#e3f2fd
    style TOKEN fill:#e8f5e8
    style CONFIG fill:#fff3e0
    style METRICS fill:#fce4ec
```

## API Architecture

### API Design Patterns

```mermaid
graph TB
    subgraph "Client Layer"
        STREAM[Streamlit<br/>Interface]
        COMP[UI Components]
        STATE[Session State]
    end
    
    subgraph "Service Layer"
        PERSONA[Persona Service]
        CHAT[Chat Service]
        CONFIG[Config Service]
    end
    
    subgraph "Integration Layer"
        AOI[Azure OpenAI<br/>Client]
        AUTH[Auth Provider]
        LOG[Logging Service]
    end
    
    subgraph "External Services"
        OPENAI[Azure OpenAI<br/>API]
        INSIGHTS[Application<br/>Insights]
        IDENTITY[Managed<br/>Identity]
    end
    
    STREAM --> COMP
    COMP --> STATE
    
    STATE --> PERSONA
    STATE --> CHAT
    STATE --> CONFIG
    
    PERSONA --> AOI
    CHAT --> AOI
    CONFIG --> AUTH
    
    AOI --> OPENAI
    AUTH --> IDENTITY
    LOG --> INSIGHTS
    
    style STREAM fill:#e3f2fd
    style PERSONA fill:#e8f5e8
    style AOI fill:#fff3e0
    style OPENAI fill:#fce4ec
```

## Disaster Recovery Architecture

### Backup and Recovery Strategy

```mermaid
graph TB
    subgraph "Backup Strategy"
        CONFIG[Configuration<br/>Backup]
        CODE[Source Code<br/>GitHub]
        INFRA[Infrastructure<br/>as Code]
    end
    
    subgraph "Recovery Procedures"
        REDEPLOY[Infrastructure<br/>Redeployment]
        RESTORE[Configuration<br/>Restore]
        VALIDATE[Service<br/>Validation]
    end
    
    subgraph "Business Continuity"
        MONITOR[Health<br/>Monitoring]
        FAILOVER[Manual<br/>Failover]
        COMMUNICATION[Stakeholder<br/>Communication]
    end
    
    CONFIG --> REDEPLOY
    CODE --> REDEPLOY
    INFRA --> REDEPLOY
    
    REDEPLOY --> RESTORE
    RESTORE --> VALIDATE
    
    VALIDATE --> MONITOR
    MONITOR --> FAILOVER
    FAILOVER --> COMMUNICATION
    
    style CONFIG fill:#e8f5e8
    style REDEPLOY fill:#fff3e0
    style MONITOR fill:#e3f2fd
```

## Conclusion

This architecture provides a robust, secure, and scalable foundation for the AI Discovery Cards Persona Bot. The design emphasizes:

1. **Security First**: Zero-trust authentication with comprehensive security controls
2. **Cloud Native**: Leverages Azure PaaS services for scalability and reliability
3. **Observability**: Comprehensive monitoring and alerting capabilities
4. **Maintainability**: Clear separation of concerns and documented interfaces
5. **Compliance**: Enterprise-grade security and governance controls

The modular architecture allows for easy extension and modification while maintaining security and performance standards. The extensive use of Azure managed services reduces operational overhead while providing enterprise-grade capabilities.

---

*This architecture documentation should be reviewed and updated as the system evolves and new requirements emerge.*