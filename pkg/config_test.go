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
	err := os.WriteFile(tmp, []byte(content), 0666)
	if err != nil {
		t.Fatal(err)
	}
	defer func() {
		if err := os.Remove(tmp); err != nil {
			t.Logf("Failed to remove test file: %v", err)
		}
	}()
	cfg, err := LoadConfig(tmp)
	if err != nil {
		t.Fatal(err)
	}
	if len(cfg.Paths) != 1 || len(cfg.KindPaths["X"]) != 1 {
		t.Fatalf("expected global 1 and kind X 1, got %v %v", len(cfg.Paths), len(cfg.KindPaths["X"]))
	}
}
