package main

import (
	"fmt"

	"github.com/aws/aws-lambda-go/lambda"
)

// lambda handler to print the event
func Handler(event interface{}) (string, error) {
	fmt.Println(event)
	return "OK", nil
}

func main() {
	lambda.Start(Handler)
}
