package main

import (
	"bufio"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"

	"github.com/aws/aws-lambda-go/lambda"
)

// Event is the input event for the Lambda function.
type Event struct {
	Targets []string `json:"targets"`
	Args    []string `json:"args"`
}

// Response is the output response for the Lambda function.
type Response struct {
	Output string `json:"output"`
	Error  string `json:"error"`
}

// Variables for the nuclei binary, filesystem location, and temporary files
const nucleiBinary = "/opt/nuclei"
const fileSystem = "/tmp/"
const targetsFile = "/tmp/targets.txt"
const scanOutput = "/tmp/output.json"

func handler(ctx context.Context, event Event) (Response, error) {
	// Set the $HOME environment so nuclei can write inside of lambda
	os.Setenv("HOME", fileSystem)

	// Check to see if you have Args and Command in the event
	if len(event.Targets) == 0 || len(event.Args) == 0 {
		return Response{
			Error: "Nuclei requires a targets and args to run. Please specify the target(s) and args within the event.",
		}, nil
	}

	// Print debugging
	fmt.Println("Targets: ", event.Targets)
	fmt.Println("Args: ", event.Args)
	fmt.Println("Length of Targets: ", len(event.Targets))
	// Check to see if the target is a single target or a list of targets
	if len(event.Targets) == 1 {
		// If it's a single target it prepends -u target to the args
		event.Args = append([]string{"-u", event.Targets[0]}, event.Args...)
	} else {
		// If it's a list of targets write them to a file and prepends -l targets.txt to the args
		targetsFile, err := writeTargets(event.Targets)
		if err != nil {
			return Response{
				Error: err.Error(),
			}, nil
		}
		event.Args = append([]string{"-l", targetsFile}, event.Args...)
	}

	// Check to see if it contains -json, to write the file to disk and return the findings in json
	jsonExport := false
	if contains(event.Args, "-json") {
		event.Args = append(event.Args, "-o", scanOutput, "-silent")
		// Attempt to delete the file if still warm
		err := os.Remove(scanOutput)
		if err != nil {
			return Response{
				Error: err.Error(),
			}, nil
		}
		// Set jsonExport to true
		jsonExport = true
	}

	// Run the nuclei binary with the command and args
	cmd := exec.Command(nucleiBinary, event.Args...)
	// Print the command to the console for debugging
	fmt.Printf("%s %v\n", nucleiBinary, event.Args)
	output, err := cmd.CombinedOutput()
	base64output := base64.StdEncoding.EncodeToString([]byte(output))
	if err != nil {
		return Response{
			Output: string(base64output),
			Error:  err.Error(),
		}, nil
	}

	// If the output was specified to json; read the file, parse the json, and return the findings
	if jsonExport {
		findings, err := jsonFindings()
		// convert to json string
		jsonFindings, err := json.Marshal(findings)
		if err != nil {
			return Response{
				Output: string(output),
				Error:  err.Error(),
			}, nil
		}
		// If there was an error return command line output
		if err != nil {
			return Response{
				Output: string(output),
				Error:  err.Error(),
			}, nil
		}
		return Response{
			Output: string(jsonFindings),
		}, nil
	}

	// Return the output of the successful command in base64
	return Response{
		Output: string(base64output),
	}, nil
}

// Write targets to a file on disk and return filename
func writeTargets(targets []string) (string, error) {
	// Check if the targets file exists, if it does delete it
	if _, err := os.Stat(targetsFile); err == nil {
		os.Remove(targetsFile)
	}

	// Create a file
	file, err := os.Create(targetsFile)
	if err != nil {
		return "", err
	}
	defer file.Close()

	// Write the list to the file.
	for _, target := range targets {
		_, err := file.WriteString(target + "\n")
		if err != nil {
			// Handle the error.
		}
	}

	// Print the contents of the file to the console for debugging
	data, err := os.ReadFile(targetsFile)
	if err != nil {
		return "", err
	}
	fmt.Println(string(data))

	// Return the filename
	return targetsFile, nil
}

// jsonFindings reads the output.json file and returns the findings
func jsonFindings() ([]interface{}, error) {
	file, err := os.Open(scanOutput)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	// Create a scanner to read the file line by line
	scanner := bufio.NewScanner(file)

	// Iterate through the file and append the findings to the findings array
	var findings []interface{}
	for scanner.Scan() {
		var data interface{}
		if err := json.Unmarshal(scanner.Bytes(), &data); err != nil {
			return nil, err
		}
		findings = append(findings, data)
	}

	// Check for errors while reading the file
	if err := scanner.Err(); err != nil {
		return nil, err
	}

	// Return the findings
	return findings, nil
}

// Contains checks to see if a string is in a slice of strings
func contains(elems []string, v string) bool {
	for _, s := range elems {
		if v == s {
			return true
		}
	}
	return false
}

func main() {
	lambda.Start(handler)
}
