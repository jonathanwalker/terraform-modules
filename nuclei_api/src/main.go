package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
)

type Event struct {
	Name string `json:"name"`
}

func handler(ctx context.Context, event Event) (interface{}, error) {
	// Print the name
	fmt.Println("Name:", event.Name)

	// Print the execution method
	if ctx.Value("invoked_function_arn") != nil {
		fmt.Println("Executed via: API Gateway")
	} else {
		fmt.Println("Executed via: Direct Lambda Invocation")
	}

	// Return a response to API Gateway
	return map[string]string{
		"message": fmt.Sprintf("Hello %s", event.Name),
	}, nil
}

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		// Parse the request body
		var event Event
		err := json.NewDecoder(r.Body).Decode(&event)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		// Invoke the handler with a nil context
		res, err := handler(nil, event)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// Encode the response as JSON
		resData, err := json.Marshal(res)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// Set the Content-Type header and write the response
		w.Header().Set("Content-Type", "application/json")
		w.Write(resData)
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
