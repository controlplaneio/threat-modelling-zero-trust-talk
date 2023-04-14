package setup

import (
	"github.com/controlplaneio/threat-modelling-zero-trust-talk/opa-istio-kms/internal"
	"github.com/open-policy-agent/opa/bundle"
	"github.com/open-policy-agent/opa/cmd"
	"github.com/spf13/cobra"
)

var commandsWithAws = map[string]bool{
	"build <path> [<path> [...]]": true,
	"run":                         true,
	"sign <path> [<path> [...]]":  true,
}

// SetupRootCommand can be used to add flags to the root OPA command
// and setup a PreRun hook to run any initialization.
func SetupRootCommand(additionalCommands *map[string]bool) *cobra.Command {
	if additionalCommands != nil {
		// add any additional commands to list that will be wrapped
		for k, v := range *additionalCommands {
			commandsWithAws[k] = v
		}
	}

	// Add any additional cmd parameters needed...

	cmd.RootCommand.PersistentPreRun = func(command *cobra.Command, args []string) {
		if _, ok := commandsWithAws[command.Use]; ok {
			bundle.RegisterSigner("aws-kms", &internal.AwsKmsSigner{})
			bundle.RegisterVerifier("aws-kms", &internal.AwsKmsVerifier{})
		}
	}

	return cmd.RootCommand
}
