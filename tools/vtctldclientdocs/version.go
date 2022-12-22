package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

type version struct {
	Ref        string
	DocVersion string
}

func (v version) Dir(root string) string {
	return filepath.Join(root, "content", "en", "docs", v.DocVersion, "reference", "programs", "vtctldclient")
}

func (v version) GenerateDocs(workdir string, vitessDir string, docgenPath string) (err error) {
	debugf("chdir %s", vitessDir)
	if err = os.Chdir(vitessDir); err != nil {
		return err
	}

	defer func() {
		debugf("chdir %s", workdir)
		if cderr := os.Chdir(workdir); cderr != nil {
			if err == nil {
				err = cderr
			}
		}
	}()

	gitCheckout := exec.Command("git", "checkout", v.Ref)
	debugf(gitCheckout.String())
	if err = gitCheckout.Run(); err != nil {
		return err
	}

	defer func() {
		gitCheckout := exec.Command("git", "checkout", "-")
		debugf(gitCheckout.String())
		if checkoutErr := gitCheckout.Run(); checkoutErr != nil {
			if err == nil {
				err = checkoutErr
			}
		}
	}()

	if err = isDir(filepath.Join(vitessDir, docgenPath)); err != nil {
		err = fmt.Errorf("cannot find docgen tool directory: %w", err)
		return err
	}

	docgen := exec.Command("go", "run", docgenPath, "-d", v.Dir(workdir))
	debugf(docgen.String())
	if err = docgen.Run(); err != nil {
		return err
	}

	return err
}
