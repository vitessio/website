/*
Copyright 2023 The Vitess Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
)

type version struct {
	Ref        string
	DocVersion string
}

func (v version) Dir(root string) string {
	return filepath.Join(root, "content", "en", "docs", v.DocVersion, "reference", "programs", binaryName)
}

func (v version) GenerateDocs(workdir string, vitessDir string, docgenPath string, graceful bool) (err error) {
	debugf("chdir %s", vitessDir)
	if err = os.Chdir(vitessDir); err != nil {
		return err
	}

	defer func() {
		debugf("in defer: chdir %s", workdir)
		if cderr := os.Chdir(workdir); cderr != nil {
			if err == nil {
				err = cderr
			}
		}
	}()
	if v.Ref != "HEAD" {
		gitCheckout := exec.Command("git", "checkout", v.Ref)
		if output, err := gitCheckout.CombinedOutput(); err != nil {
			debugf("output: %s, err: %s", output, err)
			return fmt.Errorf("failed to checkout git ref %q in %s: %w\nOutput: %s\nHint: run 'cd %s && git fetch --all --tags' to fetch all refs", v.Ref, vitessDir, err, string(output), vitessDir)
		}
		defer func() {
			gitCheckout := exec.Command("git", "checkout", "-")
			if output, checkoutErr := gitCheckout.CombinedOutput(); checkoutErr != nil {
				if err == nil {
					err = checkoutErr
				}
				debugf("output: %s, err: %s", output, checkoutErr)
			}
		}()
	}

	if err = isDir(filepath.Join(vitessDir, docgenPath)); err != nil {
		err = fmt.Errorf("cannot find docgen tool directory: %w", err)
		if graceful {
			log.Printf("[warning] %s", err)
			return nil
		}

		return err
	}

	docgen := exec.Command("go", "run", docgenPath, "-d", v.Dir(workdir))
	debugf(docgen.String())
	var output []byte
	if output, err = docgen.CombinedOutput(); err != nil {
		debugf("docgen output: %s, err %s", output, err)
		return err
	}
	debugf("docgen output: %s", output)
	return err
}
