package main

import (
	"fmt"
)

// lambda handler to print the event
func Handler(event interface{}) (string, error) {
	fmt.Println(event)
	return "OK", nil
}
