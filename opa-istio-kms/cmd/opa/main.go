package main

import (
	"fmt"
	"github.com/controlplaneio/threat-modelling-zero-trust-talk/opa-istio-kms/setup"
	"github.com/open-policy-agent/opa-envoy-plugin/plugin"
	"github.com/open-policy-agent/opa/runtime"
	"os"
)

func main() {
	runtime.RegisterPlugin("envoy.ext_authz.grpc", plugin.Factory{}) // for backwards compatibility
	runtime.RegisterPlugin(plugin.PluginName, plugin.Factory{})

	cmd := setup.SetupRootCommand(nil)

	if err := cmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
