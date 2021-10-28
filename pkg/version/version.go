package version

import (
	"strings"
)

var (
	Program      = "flannel"
	ProgramUpper = strings.ToUpper(Program)
	Version      = "dev"
	GitCommit    = "HEAD"
)
