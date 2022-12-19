package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/sns"
	"github.com/mmcdole/gofeed"
)

// Items extracted from the RSS feed
type rssFeedItem struct {
	Title       string
	Link        string
	Published   time.Time
	Description string
}

// Configuration for rss, state dynamodb table, and alert sns topic
type config struct {
	RssFeedURL    string
	HoursSince    int
	RssFilter     string
	DynamodbTable string
	AlertTopic    string
	Region        string
}

// Lambda Success Response
type Response struct {
	Message string `json:"message"`
}

func main() {
	lambda.Start(HandleRequest)
}

func HandleRequest(ctx context.Context) (Response, error) {
	// Read config from environment
	cfg, err := readConfigFromEnv()
	if err != nil {
		return Response{Message: "Failed"}, fmt.Errorf("Error getting session: %v", err)
	}

	// Create a new AWS session
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(cfg.Region)},
	)
	if err != nil {
		return Response{Message: "Failed"}, fmt.Errorf("Error getting session: %v", err)
	}

	// Initialize SNS service
	snsSvc := sns.New(sess)

	// Initialize DynamoDB service
	ddbSvc := dynamodb.New(sess)

	// Fetch the rss feed
	feed, err := gofeed.NewParser().ParseURL(cfg.RssFeedURL)
	if err != nil {
		return Response{Message: "Failed"}, fmt.Errorf("Error parsing rss feed: %v", err)
	}

	// Empty slice of rss feed items to be popuplated
	var rssFeedItems []rssFeedItem
	// Loop through the items in the rss feed
	for _, item := range feed.Items {
		// Identify the date of the rss feed item
		published, err := parseDate(item)
		if err != nil {
			return Response{Message: "Failed"}, fmt.Errorf("Error parsing date: %v", err)
		}

		// If the item is newer than hoursSince, add it to the slice
		if time.Since(published) < time.Duration(cfg.HoursSince)*time.Hour {
			rssFeedItems = append(rssFeedItems, rssFeedItem{
				Title:       item.Title,
				Link:        item.Link,
				Published:   published,
				Description: item.Description,
			})
		}
	}

	// If the rssFilter is not empty, filter the rss feed items
	if cfg.RssFilter != "" {
		rssFeedItems = filterRSSFeedItems(rssFeedItems, cfg.RssFilter)
	}

	// Loop through the rss feed items
	for _, item := range rssFeedItems {
		// Check if the item has already been alerted
		if previouslyAlerted(item, ddbSvc, cfg.DynamodbTable, int64(cfg.HoursSince)) == false {
			// Log that it has been previously alerted on
			log.Printf("Alert \"%s\" has not been alerted on, sending to SNS", item.Title)
			// Send to sns
			err := sendNotification(item, snsSvc, cfg.AlertTopic)
			if err != nil {
				return Response{Message: "Failed"}, fmt.Errorf("Error sending sns notification: %v", err)
			}
		} else {
			log.Printf("%s has already alerted on.", item.Title)
		}
	}

	return Response{
		Message: "Success",
	}, nil
}

// Read config from environment
func readConfigFromEnv() (*config, error) {
	// Feed URL to consume
	rssFeedURL := os.Getenv("RSS_FEED_URL")
	if rssFeedURL == "" {
		return nil, fmt.Errorf("RSS_FEED_URL must be set")
	}

	// Retrieve number of hours since the last rss feed item
	hoursSinceStr := os.Getenv("HOURS_SINCE")
	if hoursSinceStr == "" {
		return nil, fmt.Errorf("HOURS_SINCE must be set")
	}
	hoursSince, err := strconv.Atoi(hoursSinceStr)
	if err != nil {
		return nil, fmt.Errorf("Error parsing HOURS_SINCE: %v", err)
	}

	// DynamoDB table to store state
	dynamodbTable := os.Getenv("DYNAMODB_TABLE")
	if dynamodbTable == "" {
		return nil, fmt.Errorf("DYNAMODB_TABLE must be set")
	}

	// SNS topic to send alerts
	alertTopic := os.Getenv("ALERT_TOPIC")
	if alertTopic == "" {
		return nil, fmt.Errorf("ALERT_TOPIC must be set")
	}

	// Filter for the rss feed items
	rssFilter := os.Getenv("RSS_FILTER")

	return &config{
		RssFeedURL:    rssFeedURL,
		HoursSince:    hoursSince,
		RssFilter:     rssFilter,
		DynamodbTable: dynamodbTable,
		AlertTopic:    alertTopic,
		Region:        "us-east-1",
	}, nil
}

// Parse the published date of an RSS feed item
func parseDate(item *gofeed.Item) (time.Time, error) {
	// Try the "published" field first
	if item.PublishedParsed != nil {
		return *item.PublishedParsed, nil
	}

	// Try the "updated" field next
	if item.UpdatedParsed != nil {
		return *item.UpdatedParsed, nil
	}

	// feedItem as json for errors
	feedItem, _ := json.Marshal(item)

	// Try the "date" custom field
	date, ok := item.Custom["date"]
	if !ok {
		return time.Time{}, errors.New("Failed to find Published, Updated, or Custom date field: " + string(feedItem))
	}

	// Try parsing the "date" field with two different layouts
	layouts := []string{time.RFC1123, "Mon, 2 Jan 2006 15:04:05 -0700"}
	for _, layout := range layouts {
		t, err := time.Parse(layout, date)
		if err == nil {
			return t, nil
		}
	}
	return time.Time{}, errors.New("Failed to identify any date field within the RSS feed: " + string(feedItem))
}

// Filter the slice of rssFeedItems based on the given filter string
func filterRSSFeedItems(items []rssFeedItem, filter string) []rssFeedItem {
	filters := strings.Split(filter, ",")

	filteredItems := make([]rssFeedItem, 0)
	for _, item := range items {
		for _, f := range filters {
			if strings.Contains(item.Title, f) || strings.Contains(item.Link, f) || strings.Contains(item.Description, f) {
				filteredItems = append(filteredItems, item)
			}
		}
	}

	return filteredItems
}

// Send notification to sns
func sendNotification(item rssFeedItem, snsSvc *sns.SNS, topic string) error {
	// convert item to json string
	b, err := json.Marshal(item)
	if err != nil {
		return fmt.Errorf("Error marshalling item to JSON: %v", err)
	}

	// Send item to sns
	params := &sns.PublishInput{
		Message:  aws.String(string(b)),
		TopicArn: aws.String(topic),
	}
	message, err := snsSvc.Publish(params)
	if err != nil {
		return fmt.Errorf("Error publishing to SNS: %v", err)
	}

	// Log the message id and item.Title
	log.Printf("Send notification to SNS at %s with the title: %s", *message.MessageId, item.Title)

	return nil
}

// Check if the rss feed has already been alerted on
func previouslyAlerted(item rssFeedItem, ddbSvc *dynamodb.DynamoDB, table string, hoursSince int64) bool {
	// Check if the item has already been alerted
	result, err := ddbSvc.GetItem(&dynamodb.GetItemInput{
		TableName: aws.String(table),
		Key: map[string]*dynamodb.AttributeValue{
			"url": {
				S: aws.String(item.Link),
			},
		},
	})
	if err != nil {
		log.Printf("Error getting item from DynamoDB: %v", err)
		return false
	}

	if result.Item == nil {
		expirationTime := time.Now().Add(time.Duration(hoursSince) + 72).Unix()
		_, err := ddbSvc.PutItem(&dynamodb.PutItemInput{
			TableName: aws.String(table),
			Item: map[string]*dynamodb.AttributeValue{
				"url": {
					S: aws.String(item.Link),
				},
				"title": {
					S: aws.String(item.Title),
				},
				"description": {
					S: aws.String(item.Description),
				},
				"published": {
					S: aws.String(item.Published.Format(time.RFC3339)),
				},
				"alerted_at": {
					S: aws.String(time.Now().Format(time.RFC3339)),
				},
				"ttl": {
					N: aws.String(fmt.Sprintf("%d", expirationTime)),
				},
			},
		})
		// Log the result of the put item
		log.Printf("Alert not in the table, adding \"%s\" as the primary key for the alert \"%v\"", item.Link, item.Title)
		if err != nil {
			log.Printf("Error putting item in DynamoDB: %v", err)
		}

		return false
	}
	return true
}
