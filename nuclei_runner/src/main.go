package main

import (
	"bufio"
	"context"
	"encoding/base64"
	"encoding/json"
	"os"
	"os/exec"

	"github.com/aws/aws-lambda-go/lambda"
)

// Event is the input event for the Lambda function.
type Event struct {
	Command string   `json:"command"`
	Args    []string `json:"args"`
}

// Response is the output response for the Lambda function.
type Response struct {
	Output string `json:"output"`
	Error  string `json:"error"`
}

// Lambda layer stores the nuclei binary in /opt/nuclei
const nucleiBinary = "/opt/nuclei"

func handler(ctx context.Context, event Event) (Response, error) {
	// Check to see if you have Args and Command in the event
	if event.Command == "" || len(event.Args) == 0 {
		return Response{
			Error: "Nuclei requires a command and args to run. Please specify a command and args within the event. Example: {\"Command\": \"/opt/nuclei\", \"Args\": [\"-u\", \"https://example.com\"]}",
		}, nil
	}

	// Check to see if it contains -json
	jsonExport := false
	if contains(event.Args, "-json") {
		event.Args = append(event.Args, "-o", "/tmp/output.json", "-silent")
		// delete the output file if it exists
		os.Remove("/tmp/output.json")
		// Set jsonExport to true
		jsonExport = true
	}

	// Set the $HOME environment variable to /tmp so that nuclei can write to the filesystem
	homePath := "/tmp/"
	os.Setenv("HOME", homePath)

	// Run the nuclei binary with the command and args
	cmd := exec.Command(nucleiBinary, event.Args...)
	output, err := cmd.CombinedOutput()

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

	// If there is an error, return the error
	if err != nil {
		return Response{
			Output: string(output),
			Error:  err.Error(),
		}, nil
	}

	// Return the output of the command
	// Convert output to base64
	base64output := base64.StdEncoding.EncodeToString([]byte(output))
	return Response{
		Output: string(base64output),
	}, nil
}

// jsonFindings reads the output.json file and returns the findings
func jsonFindings() ([]interface{}, error) {
	file, err := os.Open("/tmp/output.json")
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
