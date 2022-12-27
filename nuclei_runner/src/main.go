package main

import (
	"context"
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

func handler(ctx context.Context, event Event) (Response, error) {
	// Check to see if you have Args and Command in the event
	if event.Command == "" || len(event.Args) == 0 {
		return Response{
			Error: "command and args are required",
		}, nil
	}
	// Set the $HOME environment variable to /tmp so that nuclei can write to the filesystem
	homePath := "/tmp/"
	os.Setenv("HOME", homePath)

	// Run the nuclei binary with the command and args
	cmd := exec.Command(event.Command, event.Args...)
	output, err := cmd.CombinedOutput()

	// If there is an error, return the error
	if err != nil {
		return Response{
			Output: string(output),
			Error:  err.Error(),
		}, nil
	}

	// Return the output of the command
	return Response{
		Output: string(output),
	}, nil
}

func main() {
	lambda.Start(handler)
}
