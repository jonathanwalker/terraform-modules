package main

import (
	"encoding/json"
	"fmt"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

// struct of eventName, eventtime, s3bucket, s3key, size, and useridentity
type S3Event struct {
	EventName    string `json:"eventName"`
	EventTime    string `json:"eventTime"`
	S3Bucket     string `json:"s3Bucket"`
	S3Key        string `json:"s3Key"`
	Size         int    `json:"size"`
	UserIdentity string `json:"userIdentity"`
}

func Handler(sqsEvent events.SQSEvent) (string, error) {
	objects_changed := []S3Event{}
	for _, record := range sqsEvent.Records {
		// extract the message body from the record as interface
		var event interface{}
		err := json.Unmarshal([]byte(record.Body), &event)
		if err != nil {
			return "", err
		}

		// Store the records in a list of interface
		records := event.(map[string]interface{})["Records"].([]interface{})

		// Loop through the records and append to the list of S3Event
		var object_event S3Event
		for _, record := range records {
			record := record.(map[string]interface{})
			s3 := record["s3"].(map[string]interface{})
			bucket := s3["bucket"].(map[string]interface{})
			object := s3["object"].(map[string]interface{})
			userIdentity := record["userIdentity"].(map[string]interface{})
			object_event.EventName = record["eventName"].(string)
			object_event.EventTime = record["eventTime"].(string)
			object_event.S3Bucket = bucket["name"].(string)
			object_event.S3Key = object["key"].(string)
			object_event.Size = int(object["size"].(float64))
			object_event.UserIdentity = userIdentity["principalId"].(string)
			objects_changed = append(objects_changed, object_event)

			// Print individual files changed to cloudwatch
			e, err := json.Marshal(objects_changed)
			if err != nil {
				panic(err)
			}
			fmt.Println(string(e))
		}
	}

	// Convert all files changed to json
	e, err := json.Marshal(objects_changed)
	if err != nil {
		panic(err)
	}

	// Print the JSON-formatted string.
	fmt.Println(string(e))

	return "OK", nil
}

func main() {
	lambda.Start(Handler)
}
