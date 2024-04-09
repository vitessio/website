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
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
)

var (
	usage       = "Generates website documentation for the given binary for a given set of <vitessio/vitess-gitref>:<vitessio/website-version> pairs."
	debug       = flag.Bool("debug", false, "log debug info")
	vitessDir   = flag.String("vitess-dir", "", "path to vitess checkout")
	docGenPath  = flag.String("docgen-path", "", "path to the binary docs generator, **relative to** --vitess-dir. if blank, defaults to ./go/cmd/`binary`/docgen")
	versionStrs = flag.String("version-pairs", "main:20.0", "CSV of <gitref>:<version> pairs to generate docs for; for example, 'v19.0.3:19.0' will generate docs from the v19.0.3 tag into the content/en/19.0 subtree. ensure your vitess checkout is up-to-date (git fetch --all) before running.")

	// -graceful=false explicitly to make this harder to use en masse.
	graceful = flag.Bool("graceful", true, "skip programs/versions where either the docgen directory or target content directory is missing (under the assumption there was no setup for generated docs for that binary/version)")

	binaryName string
)

func getValidWorkdir() (string, error) {
	wd, err := os.Getwd()
	if err != nil {
		return "", fmt.Errorf("cannot determine working directory, bailing: %w", err)
	}

	if err := isDir(filepath.Join(wd, "content", "en")); err != nil {
		return "", fmt.Errorf("cannot find content/en dir in %s: %w", wd, err)
	}

	return wd, nil
}

func debugf(msg string, args ...any) {
	if !*debug {
		return
	}

	log.Printf(msg, args...)
}

func must(err error) {
	if err != nil {
		log.Fatal(err)
	}
}
func unwrap[T any](t T, err error) T {
	if err != nil {
		log.Fatal(err)
	}

	return t
}

func main() {
	flag.Usage = func() {
		fmt.Fprintf(flag.CommandLine.Output(), "Usage of %s:\n", os.Args[0])
		fmt.Fprintf(flag.CommandLine.Output(), "%s <binary>\n", os.Args[0])
		fmt.Fprintf(flag.CommandLine.Output(), "\n%s\n\n", usage)
		flag.PrintDefaults()
	}
	flag.Parse()

	binaryName = flag.Arg(0)
	if binaryName == "" {
		log.Fatalf("binary name is required")
	}

	wd := unwrap(getValidWorkdir())

	if *vitessDir == "" {
		log.Fatalf("--vitess-dir must be specified")
	}

	debugf("workdir: %s\tvitess-dir: %s\t\n", wd, *vitessDir)

	var versions []version

	for i, pair := range strings.Split(*versionStrs, ",") {
		parts := strings.Split(pair, ":")
		if len(parts) < 2 {
			log.Fatalf("bad version spec (index=%d) %s", i, pair)
		}

		version := version{
			Ref:        strings.Join(parts[:len(parts)-1], ":"),
			DocVersion: parts[len(parts)-1],
		}

		if err := isDir(version.Dir(wd)); err != nil {
			msg := fmt.Sprintf("cannot find directory for doc version %s (index=%d): %v", pair, i, err)
			if *graceful {
				log.Printf("[warning] %s", msg)
				continue
			}

			log.Fatal(msg)
		}

		versions = append(versions, version)
	}

	if *docGenPath == "" {
		*docGenPath = fmt.Sprintf("./go/cmd/%s/docgen", binaryName)
	}

	for _, version := range versions {
		must(version.GenerateDocs(wd, *vitessDir, *docGenPath, *graceful))
	}
}
