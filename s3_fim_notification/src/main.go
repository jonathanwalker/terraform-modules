package main

import (
	"encoding/json"
	"fmt"

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

func Handler(event interface{}) (string, error) {
	//
	fmt.Println(event)
	// Store the records in a list of interface
	records := event.(map[string]interface{})["Records"].([]interface{})

	// Emtpy list of S3Event
	objects_changed := []S3Event{}
	var object_event S3Event

	// Loop through the records and append to the list of S3Event
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
	}

	// Convert to json
	e, err := json.Marshal(objects_changed)
	if err != nil {
		panic(err)
	}

	// Print the JSON-formatted string.
	fmt.Println(string(e))

	return "OK", nil
}

// Map map[Records:[map[awsRegion:us-east-1 eventName:ObjectCreated:Put eventSource:aws:s3 eventTime:2022-12-14T22:14:27.050Z eventVersion:2.1 requestParameters:map[sourceIPAddress:13.67.179.50] responseElements:map[x-amz-id-2:YQaDNVlObEDbA6vRPwvb+XlX6WNPPN255dR7lzuam3KYGH6RDkTgbAwGgLYfwQggS0D2Ncvl6sV8HjCefA4Z5+bLtj5ge8TP x-amz-request-id:S0Z3WZG4QVCWGWYH] s3:map[bucket:map[arn:arn:aws:s3:::devsecopsdocs-com-static name:devsecopsdocs-com-static ownerIdentity:map[principalId:AHPTR04EZWO79]] configurationId:fim object:map[eTag:6a40c9079bbcbf2dd8b58a6a522a0ed9 key:tags/reports/index.xml sequencer:00639A4AC2C9EF831C size:1272] s3SchemaVersion:1.0] userIdentity:map[principalId:AWS:AROAR4KW6OTJZ73SFW23T:ghactions]]]]

func main() {
	lambda.Start(Handler)
}

// print example json from this map map[Records:[map[awsRegion:us-east-1 eventName:ObjectCreated:Put eventSource:aws:s3 eventTime:2022-12-14T22:14:27.050Z eventVersion:2.1 requestParameters:map[sourceIPAddress:13.67.179.50] responseElements:map[x-amz-id-2:YQaDNVlObEDbA6vRPwvb+XlX6WNPPN255dR7lzuam3KYGH6RDkTgbAwGgLYfwQggS0D2Ncvl6sV8HjCefA4Z5+bLtj5ge8TP x-amz-request-id:S0Z3WZG4QVCWGWYH] s3:map[bucket:map[arn:arn:aws:s3:::devsecopsdocs-com-static name:devsecopsdocs-com-static ownerIdentity:map[principalId:AHPTR04EZWO79]] configurationId:fim object:map[eTag:6a40c9079bbcbf2dd8b58a6a522a0ed9 key:tags/reports/index.xml sequencer:00639A4AC2C9EF831C size:1272] s3SchemaVersion:1.0] userIdentity:map[principalId:AWS:AROAR4KW6OTJZ73SFW23T:ghactions]]]]
