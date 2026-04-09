package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestExampleComplete(t *testing.T) {
	t.Log("Starting Sample Module test")

	terraformDir := "../../_example/complete"
	stateKey := "terratest/terraform-aws-acf-org-delegation.tfstate"
	backendConfig := loadBackendConfig(t, stateKey)

	// Create IAM Role
	terraformPreparation := &terraform.Options{
		TerraformDir:  terraformDir,
		NoColor:       false,
		Lock:          true,
		BackendConfig: backendConfig,
		Reconfigure:   true,
		Targets: []string{
			"module.create_provisioner",
		},
	}
	defer terraform.Destroy(t, terraformPreparation)
	terraform.InitAndApply(t, terraformPreparation)

	terraformModule := &terraform.Options{
		TerraformDir:  terraformDir,
		NoColor:       false,
		Lock:          true,
		BackendConfig: backendConfig,
		Reconfigure:   true,
	}
	defer terraform.Destroy(t, terraformModule)
	terraform.InitAndApply(t, terraformModule)

	// Retrieve the 'test_success' outputs
	testSuccessOutput := terraform.Output(t, terraformModule, "test_success")
	t.Logf("testSuccessOutput: %s", testSuccessOutput)

	// Assert that 'test_success' equals "true"
	assert.Equal(t, "true", testSuccessOutput, "The test_success output is not true")
}
