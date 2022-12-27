package main

import (
	"context"
	"fmt"
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
	// Run the nuclei CLI with the command and args from the event.
	// cmd := exec.Command(event.Command, event.Args...)
	args := []string{"-u", "https://devsecopsdocs.com", "-c", "50", "-rl", "300", "-timeout", "5", "-t", "dns/", "-stats"}
	cmd := exec.Command("/opt/nuclei", args...)
	output, err := cmd.CombinedOutput()
	fmt.Println(string(output))
	if err != nil {
		return Response{
			Output: string(output),
			Error:  err.Error(),
		}, nil
	}
	return Response{
		Output: string(output),
	}, nil
}

func main() {
	lambda.Start(handler)
}
