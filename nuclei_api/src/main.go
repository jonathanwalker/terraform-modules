package main

import (
	"context"
	"fmt"
)

type Event struct {
	Name string `json:"name"`
}

func handler(ctx context.Context, event Event) {
	// Print the name
	fmt.Println("Name:", event.Name)

	// Print the execution method
	if ctx.Value("invoked_function_arn") != nil {
		fmt.Println("Executed via: API Gateway")
	} else {
		fmt.Println("Executed via: Direct Lambda Invocation")
	}
}

func main() {
	// Create an event
	event := Event{Name: "Bob"}

	// Invoke the handler with a nil context
	handler(nil, event)
}
