# scrubectl

```
┌─┐┌─┐┬─┐┬ ┬┌┐ ┌─┐┌─┐┌┬┐┬  
└─┐│  ├┬┘│ │├┴┐├┤ │   │ │  
└─┘└─┘┴└─└─┘└─┘└─┘└─┘ ┴ ┴─┘
```

**scrubectl** is a versatile CLI tool and kubectl plugin for sanitizing Kubernetes YAML manifests by stripping out unwanted fields. Perfect for cleaning up kubectl output or preparing manifests for GitOps workflows.

[![Go Report Card](https://goreportcard.com/badge/github.com/Valinor/scrubectl)](https://goreportcard.com/report/github.com/Valinor/scrubectl)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ✨ Features

- **🎯 Configurable pruning**: Remove global paths (e.g. `status`) or kind-specific paths (e.g. `.metadata.revision` for ConfigMaps)
- **📦 Embedded defaults**: Sensible defaults built-in, no config required to get started
- **🔍 Smart config lookup**: Multiple config file locations with clear precedence
- **📤 Template export**: Generate starter config with `--export-template`
- **⚡ On-the-fly filtering**: Add extra removal paths via `--path` flags
- **🔌 Dual mode**: Works as kubectl plugin or standalone filter

## 🚀 Quick Start

### Installation

#### From Source
```bash
git clone https://github.com/Valinor/scrubectl.git
cd scrubectl
make setup  # Install dependencies
make build  # Build the binary
```

#### Via Go Install
```bash
go install github.com/Valinor/scrubectl@latest
```

### Basic Usage

```bash
# Clean kubectl output
kubectl get deployment nginx -o yaml | scrubectl

# Use as kubectl plugin (symlink kubectl-scrubectl to your PATH)
kubectl scrubectl get pod mypod

# Export default config for customization
scrubectl --export-template > ~/.config/scrubectl/config.yaml
```

## 📖 Usage Examples

### Standalone Filter

```bash
# Clean an existing manifest
cat deployment.yaml | scrubectl > deployment.clean.yaml

# With custom config
scrubectl --config ./my-config.yaml < manifest.yaml

# Add extra removal paths on the fly
cat pod.yaml | scrubectl --path metadata.labels.app --path spec.nodeName
```

### As kubectl Plugin

First, ensure `kubectl-scrubectl` is in your PATH:
```bash
# Create symlink (adjust paths as needed)
ln -s /path/to/scrubectl /usr/local/bin/kubectl-scrubectl
```

Then use it:
```bash
# Clean deployment output
kubectl scrubectl get deployment nginx

# With custom config
kubectl scrubectl get pod mypod --config ./config.yaml

# Add extra paths to remove
kubectl scrubectl get service mysvc --path metadata.annotations.foo
```

## ⚙️ Configuration

### Config File Locations (in order of precedence)

1. `--config <file>` flag
2. `$SCRUBECTLPATH/config.yaml` environment variable
3. `~/.config/scrubectl/config.yaml`
4. Embedded defaults

### Configuration Format

```yaml
# Global paths to remove from all resources
paths:
  - [status]
  - [metadata, annotations, kubectl.kubernetes.io/last-applied-configuration]
  - [metadata, ownerReferences]
  - [metadata, resourceVersion]
  - [metadata, uid]
  - [metadata, creationTimestamp]

# Kind-specific paths: only remove when 'kind' matches
kindPaths:
  ConfigMap:
    - [metadata, revision]
  Deployment:
    - [spec, template, metadata, annotations, rollout]
  Pod:
    - [spec, containers, terminationMessagePath]
    - [spec, containers, terminationMessagePolicy]
    - [spec, terminationGracePeriodSeconds]
```

### Export Template

Generate a starter config file:
```bash
scrubectl --export-template > ~/.config/scrubectl/config.yaml
```

## 🛠️ Development

### Prerequisites

- Go 1.21+
- Make

### Setup Development Environment

```bash
git clone https://github.com/Valinor/scrubectl.git
cd scrubectl
make setup    # Install all development dependencies
```

### Available Make Targets

```bash
make build         # Build the binary
make test          # Run tests
make test-coverage # Run tests with coverage report
make vet           # Run linter (golangci-lint)
make fmt           # Format code
make clean         # Clean build artifacts
make dev           # Build and run development version
make release       # Create release (requires proper git tags)
```

### Running Tests

```bash
make test                    # Basic test run
make test-verbose           # Verbose test output
make test-coverage          # Generate coverage report
```

## 📋 Example Transformation

**Input** (kubectl get deployment nginx -o yaml):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: default
  uid: 12345678-1234-1234-1234-123456789012
  resourceVersion: "12345"
  creationTimestamp: "2024-01-01T00:00:00Z"
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"apps/v1","kind":"Deployment"...}
    rollout: v2.0
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
status:
  availableReplicas: 3
  readyReplicas: 3
```

**Output** (after scrubectl):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`make test`)
5. Run linter (`make vet`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by the need to clean kubectl output for GitOps workflows
- Built with ❤️ for the Kubernetes community