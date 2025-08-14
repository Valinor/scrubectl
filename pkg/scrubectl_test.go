package scrubectl

import (
	"bytes"
	"strings"
	"testing"
)

func TestCleanGlobal(t *testing.T) {
	in := `kind: Pod
metadata:
  name: p
status: Running
`
	var out bytes.Buffer
	err := Clean(strings.NewReader(in), &out, [][]string{{"status"}}, nil)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(out.String(), "status:") {
		t.Error("status not removed")
	}
}

func TestCleanKindSpecific(t *testing.T) {
	in := `kind: ConfigMap
metadata:
  name: cm
  revision: 123
`
	var out bytes.Buffer
	err := Clean(strings.NewReader(in), &out, nil, map[string][][]string{"ConfigMap": {{"metadata", "revision"}}})
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(out.String(), "revision:") {
		t.Error("revision not removed for ConfigMap")
	}
}
