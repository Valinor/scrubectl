# scrubectl
```
┌─┐┌─┐┬─┐┬ ┬┌┐ ┌─┐┌─┐┌┬┐┬  
└─┐│  ├┬┘│ │├┴┐├┤ │   │ │  
└─┘└─┘┴└─└─┘└─┘└─┘└─┘ ┴ ┴─┘
```
**`scrubectl`** is a versatile CLI tool and kubectl plugin for sanitizing Kubernetes YAML manifests by stripping out unwanted fields. It can be used as:

* A **kubectl plugin**: `kubectl scrubectl ...`
* A **standalone filter**: `cat myfile.yaml | scrubectl`

---

## Features

* **Configurable pruning**: Remove global paths (e.g. `status`) or kind-specific paths (e.g. `.metadata.revision` for ConfigMaps).
* **Embedded default config**: Bundled sensible defaults.
* **Config lookup**:

    1. `--config /path/to/config.yaml`
    2. `$SCRUBECTLPATH/config.yaml`
    3. `~/.config/scrubectl/config.yaml`
    4. **Embedded** default
* **Export template**: `--export-template` writes out the default config for easy customization.
* **On-the-fly removals**: `--path metadata.annotations.foo` to add extra pruning rules.

---

## Installation

### Via Krew (not working, work in progress)

```bash
kubectl krew install scrubectl
```

### From Source

```bash
git clone https://github.com/valinor/scrubectl.git
cd scrubectl
make all      # builds bin/kubectl-clean-yaml or bin/scrubectl
```

---

## Usage

### As a kubectl plugin (not working, work in progress)

```bash
# Basic: strip default paths
kubectl scrubectl get deploy mydeploy

# With explicit config
kubectl scrubectl get pod mypod --config ./config.yaml

# Add extra removal paths
kubectl scrubectl get svc mysvc --path metadata.annotations.foo
```

### Standalone filter

```bash
# Clean an existing YAML file
cat manifest.yaml | scrubectl > manifest.cleaned.yaml

# Read from stdin with custom config
scrubectl --config ./config.yaml < manifest.yaml
```

### Export default config template

```bash
scrubectl --export-template > ~/.config/scrubectl/config.yaml
```

Customize `config.yaml`:

```yaml
# ~/.config/scrubectl/config.yaml
paths:
  - [status]
  - [metadata, annotations, kubectl.kubernetes.io/last-applied-configuration]
kindPaths:
  ConfigMap:
    - [metadata, revision]
  Deployment:
    - [spec, template, metadata, annotations, rollout]
```

---

## Configuration Precedence

1. `--config <file>` flag
2. Directory in `SCRUBECTLPATH` environment variable
3. `$HOME/.config/scrubectl/config.yaml`
4. Embedded defaults

---

## Example

Given a Deployment YAML with status and rollout annotation:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  annotations:
    rollout: v2.0
status:
  availableReplicas: 3
spec:
  replicas: 3
status:
 ...
```

**Command**:

```bash
kubectl clean-yaml get deploy nginx
```

**Output**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 3
```

---

## Contributing

PRs welcome! 

---

## License

[MIT](LICENSE)
