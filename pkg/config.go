package scrubectl

import (
	"os"

	"gopkg.in/yaml.v3"
)

// Config holds global and kind-specific removal paths
type Config struct {
	Paths     [][]string            `yaml:"paths"`
	KindPaths map[string][][]string `yaml:"kindPaths"`
}

// LoadConfig reads YAML config
func LoadConfig(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var cfg Config
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return nil, err
	}
	if cfg.KindPaths == nil {
		cfg.KindPaths = make(map[string][][]string)
	}
	return &cfg, nil
}
