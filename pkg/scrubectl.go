package scrubectl

import (
	"io"

	"gopkg.in/yaml.v3"
)

// Clean removes global and kind-specific paths
func Clean(in io.Reader, out io.Writer, global [][]string, kindMap map[string][][]string) error {
	dec := yaml.NewDecoder(in)
	enc := yaml.NewEncoder(out)
	enc.SetIndent(2)

	for {
		var doc yaml.Node
		if err := dec.Decode(&doc); err == io.EOF {
			break
		} else if err != nil {
			return err
		}

		// Determine kind
		kind := getKind(&doc)

		// Remove global
		for _, p := range global {
			removePath(&doc, p)
		}
		// Remove kind-specific
		if paths, ok := kindMap[kind]; ok {
			for _, p := range paths {
				removePath(&doc, p)
			}
		}

		if err := enc.Encode(&doc); err != nil {
			return err
		}
	}
	return nil
}

// getKind extracts `.kind`
func getKind(doc *yaml.Node) string {
	if doc.Kind == yaml.DocumentNode && len(doc.Content) > 0 {
		root := doc.Content[0]
		for i := 0; i < len(root.Content)-1; i += 2 {
			if root.Content[i].Value == "kind" {
				return root.Content[i+1].Value
			}
		}
	}
	return ""
}

// removePath deletes mapping entries matching the path in the YAML node tree
func removePath(node *yaml.Node, path []string) {
	if len(path) == 0 {
		return
	}
	switch node.Kind {
	case yaml.DocumentNode:
		for _, c := range node.Content {
			removePath(c, path)
		}

	case yaml.MappingNode:
		for i := 0; i < len(node.Content)-1; i += 2 {
			k := node.Content[i]
			v := node.Content[i+1]
			if k.Value == path[0] {
				if len(path) == 1 {
					node.Content = append(node.Content[:i], node.Content[i+2:]...)
					i -= 2
					continue
				}
				removePath(v, path[1:])
			}
		}

	case yaml.SequenceNode:
		for _, c := range node.Content {
			removePath(c, path)
		}

	case yaml.ScalarNode, yaml.AliasNode:
		// no-op for leaf nodes

	default:
		// other node kinds are ignored
	}
}
