package scrubectl

import (
	"os"
	"testing"
)

func TestLoadConfig(t *testing.T) {
	content := `paths:
  - [a]
kindPaths:
  X:
    - [b]
`
	tmp := "test_config.yaml"
	os.WriteFile(tmp, []byte(content), 0666)
	defer os.Remove(tmp)
	cfg, err := LoadConfig(tmp)
	if err != nil {
		t.Fatal(err)
	}
	if len(cfg.Paths) != 1 || len(cfg.KindPaths["X"]) != 1 {
		t.Fatalf("expected global 1 and kind X 1, got %v %v", len(cfg.Paths), len(cfg.KindPaths["X"]))
	}
}
