package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/lambda"
)

// Lambda Success Response
type Response struct {
	Message string `json:"message"`
}

func main() {
	lambda.Start(HandleRequest)
}

func HandleRequest(ctx context.Context) (Response, error) {
	fmt.Println("Hello World!")

	// Slack
	msg := SlackMessage{
		Username: "GoBot",
		Text:     "This is an alert message from Go!",
		Attachments: []Attachment{
			Attachment{
				Color:      "good",
				AuthorName: "GoBot",
				Title:      "Alert",
				TitleLink:  "https://example.com",
				Text:       "This is the body of the alert message.",
				Fields: []Field{
					Field{
						Title: "Priority",
						Value: "Low",
						Short: false,
					},
				},
			},
		},
	}
	err := SendSlackWebhook(slackWebhookURL, msg)
	if err != nil {
		fmt.Printf("Error sending message: %s", err)
	}

	return Response{
		Message: "Success",
	}, nil
}

// Slack
var slackWebhookURL = os.Getenv("SLACK_WEBHOOK")

type SlackMessage struct {
	Username    string       `json:"username"`
	Text        string       `json:"text"`
	Attachments []Attachment `json:"attachments"`
}

type Attachment struct {
	Color      string  `json:"color"`
	AuthorName string  `json:"author_name"`
	Title      string  `json:"title"`
	TitleLink  string  `json:"title_link"`
	Text       string  `json:"text"`
	Fields     []Field `json:"fields"`
}

type Field struct {
	Title string `json:"title"`
	Value string `json:"value"`
	Short bool   `json:"short"`
}

func SendSlackWebhook(webhookURL string, msg SlackMessage) error {
	// Encode the message as JSON
	payload, err := json.Marshal(msg)
	if err != nil {
		return err
	}

	// Create an HTTP request
	req, err := http.NewRequest("POST", webhookURL, bytes.NewBuffer(payload))
	if err != nil {
		return err
	}

	// Set the Content-Type header
	req.Header.Set("Content-Type", "application/json")

	// Send the request and check for errors
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return fmt.Errorf("non-200 status code: %d", resp.StatusCode)
	}

	return nil
}
