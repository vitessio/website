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
	usage       = "Generates website documentation for the `vtctldclient` binary for a given set of <vitessio/vitess-gitref>:<vitessio/website-version> pairs."
	debug       = flag.Bool("debug", false, "log debug info")
	vitessDir   = flag.String("vitess-dir", "", "path to vitess checkout")
	docGenPath  = flag.String("vtctldclientdocgen-path", "./go/cmd/vtctldclient/docgen", "path to the vtctldclient doc generator, **relative to** --vitess-dir")
	versionStrs = flag.String("version-pairs", "main:16.0", "CSV of <gitref>:<version> pairs to generate docs for; for example, 'v15.0.2:15.0' will generate docs from the v15.0.2 tag into the content/en/15.0 subtree. ensure your vitess checkout is up-to-date (git fetch --all) before running.")
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
		fmt.Fprintf(flag.CommandLine.Output(), "\n%s\n\n", usage)
		flag.PrintDefaults()
	}
	flag.Parse()

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
			log.Fatalf("cannot find directory for doc version %s (index=%d): %v", pair, i, err)
		}

		versions = append(versions, version)
	}

	for _, version := range versions {
		must(version.GenerateDocs(wd, *vitessDir, *docGenPath))
	}
}
