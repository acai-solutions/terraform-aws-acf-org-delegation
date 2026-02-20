package test

import (
	"encoding/json"
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func loadBackendConfig(t *testing.T) map[string]interface{} {
	backendConfig := map[string]interface{}{}
	data, err := os.ReadFile("backend.json")
	if err != nil {
		t.Logf("No backend.json found, using local state: %v", err)
		return nil
	}
	if err := json.Unmarshal(data, &backendConfig); err != nil {
		t.Fatalf("Failed to parse backend.json: %v", err)
	}
	return backendConfig
}

func TestExampleComplete(t *testing.T) {
	t.Log("Starting Sample Module test")

	terraformDir := "../../examples/complete"
	backendConfig := loadBackendConfig(t)

	// Create IAM Role
	terraformPreparation := &terraform.Options{
		TerraformDir:  terraformDir,
		NoColor:       false,
		Lock:          true,
		BackendConfig: backendConfig,
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
	}
	defer terraform.Destroy(t, terraformModule)
	terraform.InitAndApply(t, terraformModule)

	// Retrieve the 'test_success' outputs
	testSuccessOutput := terraform.Output(t, terraformModule, "test_success")
	t.Logf("testSuccessOutput: %s", testSuccessOutput)

	// Assert that 'test_success' equals "true"
	assert.Equal(t, "true", testSuccessOutput, "The test_success output is not true")
}
