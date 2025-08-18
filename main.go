package main

import (
	"bytes"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	cleaner "scrubectl/pkg"
	"strings"
)

func main() {
	// Split args: before "--" to kubectl, after to plugin
	args := os.Args[1:]
	sep := indexOf(args, "--")
	var kubectlArgs, pluginArgs []string
	if sep >= 0 {
		kubectlArgs, pluginArgs = args[:sep], args[sep+1:]
	} else {
		kubectlArgs, pluginArgs = args, nil
	}

	// Plugin flags
	cfgPath := flag.String("config", "config.yaml", "Config file path")
	var extraPaths multiString
	flagSet := flag.NewFlagSet("clean-yaml", flag.ExitOnError)
	flagSet.StringVar(cfgPath, "config", *cfgPath, "Config file path")
	flagSet.Var(&extraPaths, "path", "Additional dot-separated path to remove (global)")
	err := flagSet.Parse(pluginArgs)
	if err != nil {
		return
	}

	// Buffer for YAML input
	var inBuf bytes.Buffer

	if len(kubectlArgs) > 0 {
		// Running as kubectl plugin: ensure -o yaml
		if !hasOutputYAML(kubectlArgs) {
			kubectlArgs = append(kubectlArgs, "-o", "yaml")
		}
		// Invoke kubectl
		cmd := exec.Command("kubectl", kubectlArgs...)
		cmd.Stdout = &inBuf
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			_, err := fmt.Fprintf(os.Stderr, "kubectl error: %v\n", err)
			if err != nil {
				return
			}
			os.Exit(1)
		}
	} else {
		// No kubectl args: read from stdin (standalone)
		if _, err := io.Copy(&inBuf, os.Stdin); err != nil {
			_, err := fmt.Fprintf(os.Stderr, "stdin read error: %v\n", err)
			if err != nil {
				return
			}
			os.Exit(1)
		}
	}

	// Load config
	cfg, err := cleaner.LoadConfig(*cfgPath)
	if err != nil {
		_, err := fmt.Fprintf(os.Stderr, "config load error: %v\n", err)
		if err != nil {
			return
		}
		os.Exit(1)
	}
	for _, p := range extraPaths {
		cfg.Paths = append(cfg.Paths, splitPath(p))
	}

	// Clean
	if err := cleaner.Clean(&inBuf, os.Stdout, cfg.Paths, cfg.KindPaths); err != nil {
		_, err := fmt.Fprintf(os.Stderr, "clean error: %v\n", err)
		if err != nil {
			return
		}
		os.Exit(1)
	}
}

func indexOf(slice []string, val string) int {
	for i, s := range slice {
		if s == val {
			return i
		}
	}
	return -1
}

func hasOutputYAML(args []string) bool {
	for i, a := range args {
		if (a == "-o" || a == "--output") && i+1 < len(args) {
			if args[i+1] == "yaml" {
				return true
			}
		}
		if strings.HasPrefix(a, "--output=") && strings.HasSuffix(a, "=yaml") {
			return true
		}
	}
	return false
}

type multiString []string

func (m *multiString) String() string     { return fmt.Sprint(*m) }
func (m *multiString) Set(v string) error { *m = append(*m, v); return nil }
func splitPath(s string) []string         { return strings.Split(s, ".") }
