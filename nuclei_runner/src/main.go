package main

import (
	"bufio"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"
	"github.com/google/uuid"
)

// Event is the input event for the Lambda function.
type Event struct {
	Targets []string `json:"targets"`
	Args    []string `json:"args"`
	Output  string   `json:"output"`
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
	if len(event.Targets) == 0 || len(event.Args) == 0 || event.Output == "" {
		return Response{
			Error: "Nuclei requires a targets, args, and output to run. Please specify the target(s), args, and output within the event.",
		}, nil
	}

	// Check to see if it is a single target or multiple
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

	// If the output is json or s3 then output as json
	if event.Output == "json" || event.Output == "s3" {
		event.Args = append(event.Args, "-json", "-o", scanOutput, "-silent")
	}

	// Run the nuclei binary with the command and args
	cmd := exec.Command(nucleiBinary, event.Args...)
	output, err := cmd.CombinedOutput()
	base64output := base64.StdEncoding.EncodeToString([]byte(output))
	if err != nil {
		return Response{
			Output: string(base64output),
			Error:  err.Error(),
		}, nil
	}

	// Send the scan results to the sink
	if event.Output == "json" {
		findings, err := jsonOutputFindings(scanOutput)
		// convert it to json
		jsonFindings, err := json.Marshal(findings)
		if err != nil {
			return Response{
				Output: string(output),
				Error:  err.Error(),
			}, nil
		}
		return Response{
			Output: string(jsonFindings),
		}, nil
	} else if event.Output == "cmd" {
		return Response{
			Output: string(base64output),
		}, nil
	} else if event.Output == "s3" {
		// Read the findings as []interface{}
		findings, err := jsonOutputFindings(scanOutput)
		if err != nil {
			return Response{
				Output: string(output),
				Error:  err.Error(),
			}, nil
		}
		// Write the findings to a file and upload to s3
		s3Key, err := writeAndUploadFindings(findings)
		if err != nil {
			return Response{
				Output: string(output),
				Error:  err.Error(),
			}, nil
		}

		// Return the s3 key
		return Response{
			Output: s3Key,
		}, nil
	} else {
		return Response{
			Output: string(output),
			Error:  "Output type not supported. Please specify json or cmd.",
		}, nil
	}
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

	// Return the filename
	return targetsFile, nil
}

// jsonFindings reads the output.json file and returns the findings
func jsonOutputFindings(scanOutputFile string) ([]interface{}, error) {
	file, err := os.Open(scanOutputFile)
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

// Takes in []interface{}, iterates through it, writes it to a file based on the date, and uploads it to S3
func writeAndUploadFindings(findings []interface{}) (string, error) {
	// Bucket and region
	region := os.Getenv("AWS_REGION")
	bucket := os.Getenv("BUCKET_NAME")
	// Iterate through the interface and convert to a slice of strings for writing to a file
	var s3Findings []string
	for _, finding := range findings {
		jsonFinding, err := json.Marshal(finding)
		if err != nil {
			return "failed to upload to s3", err
		}
		s3Findings = append(s3Findings, string(jsonFinding))
	}

	// Two variables for filename, must be unique on execution, and s3 key partitioned with findings/year/month/day/hour/nuclei-findings-<timestamp>.json
	t := time.Now()
	uuid := uuid.New()
	s3Key := fmt.Sprintf("findings/%d/%d/%d/%d/nuclei-findings-%d.json", t.Year(), t.Month(), t.Day(), t.Hour(), uuid)
	filename := fmt.Sprintf("nuclei-findings-%s.json", uuid)

	// Write the findings to a file
	file, err := os.Create(fileSystem + filename)
	if err != nil {
		return "Failed to write to filesystem", err
	}
	defer file.Close()

	// Write the list to the file.
	for _, finding := range s3Findings {
		_, err := file.WriteString(finding + "\n")
		if err != nil {
			return "Failed to write json to file", err
		}
	}

	// Upload the file to S3
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(region)},
	)
	if err != nil {
		return "Failed to create session", err
	}

	// Create an uploader with the session and default options
	uploader := s3manager.NewUploader(sess)

	// Open the file for use
	file, err = os.Open(fileSystem + filename)
	if err != nil {
		return "Failed to open file", err
	}

	// Upload the file to S3.
	result, err := uploader.Upload(&s3manager.UploadInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(s3Key),
		Body:   file,
	})
	if err != nil {
		return "Failed to upload file", err
	}

	return aws.StringValue(&result.Location), nil
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
