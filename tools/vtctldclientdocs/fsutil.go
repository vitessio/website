package main

import (
	"errors"
	"fmt"
	"os"
)

func isDir(path string) error {
	dir, err := os.Stat(path)
	switch {
	case errors.Is(err, os.ErrNotExist):
		return err
	case err != nil:
		return fmt.Errorf("failed to stat %s: %w", path, err)
	case !dir.IsDir():
		return fmt.Errorf("%s is not a directory", path)
	}

	return nil
}
