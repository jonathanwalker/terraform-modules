package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/sns"
	"github.com/mmcdole/gofeed"
)

// Replace with the URL of the RSS feed you want to check
var rssFeedURL = os.Getenv("RSS_FEED_URL")
var hoursSince, _ = strconv.Atoi(os.Getenv("HOURS_SINCE"))
var rssFilter = os.Getenv("RSS_FILTER")
var dynamodbTable = os.Getenv("DYNAMODB_TABLE")
var alertTopic = os.Getenv("ALERT_TOPIC")

// create struct for RSS feed items including title, link, published date and description
type rssFeedItem struct {
	Title       string
	Link        string
	Published   time.Time
	Description string
}

func main() {
	handler(context.TODO())
}

func handler(ctx context.Context) {
	// Fetch the rss feed
	feed, err := gofeed.NewParser().ParseURL(rssFeedURL)
	if err != nil {
		fmt.Println(err)
	}

	// Empty slice of rss feed items to be popuplated
	var rssFeedItems []rssFeedItem
	// Loop through the items in the rss feed
	for _, item := range feed.Items {
		// Identify the date of the rss feed item
		published, err := parseDate(item)
		if err != nil {
			fmt.Errorf("Error parsing date: %v", err)
		}

		// If the item is newer than hoursSince, add it to the slice
		if time.Since(published) < time.Duration(hoursSince)*time.Hour {
			rssFeedItems = append(rssFeedItems, rssFeedItem{
				Title:       item.Title,
				Link:        item.Link,
				Published:   published,
				Description: item.Description,
			})
		}
	}

	// If the rssFilter is not empty, filter the rss feed items
	if rssFilter != "" {
		rssFeedItems = filterRSSFeedItems(rssFeedItems, rssFilter)
	}

	// Loop through the rss feed items
	for _, item := range rssFeedItems {
		// Check if the item has already been alerted
		if previouslyAlerted(item) == false {
			// Send to sns
			sendNotification(item)
		} else {
			fmt.Println(item.Title + " has already alerted on.")
		}
	}
}

// Send notification to sns
func sendNotification(item rssFeedItem) {
	// Create a new session
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String("us-east-1")},
	)

	// conver item to json string
	b, err := json.Marshal(item)
	if err != nil {
		fmt.Println("error:", err)
	}

	// Send item to sns
	svc := sns.New(sess)
	params := &sns.PublishInput{
		Message:  aws.String(string(b)),
		TopicArn: aws.String(alertTopic),
	}
	_, err = svc.Publish(params)
	if err != nil {
		fmt.Println(err.Error())
	}
}

// Check if the rss feed has already been alerted on
func previouslyAlerted(item rssFeedItem) bool {
	// Create dynamodb client
	sess, err := session.NewSession()
	if err != nil {
		fmt.Println(err)
	}
	client := dynamodb.New(sess)

	result, err := client.GetItem(&dynamodb.GetItemInput{
		TableName: aws.String(dynamodbTable),
		Key: map[string]*dynamodb.AttributeValue{
			"url": {
				S: aws.String(item.Link),
			},
		},
	})
	if err != nil {
		fmt.Println(err)
	}

	// If the feed has not been alerted, add it to the table
	if len(result.Item) == 0 {
		// ttl of hoursSince + 72 hours
		expirationTime := time.Now().Add(time.Duration(hoursSince) + 72).Unix()
		_, err := client.PutItem(&dynamodb.PutItemInput{
			TableName: aws.String(dynamodbTable),
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
		if err != nil {
			fmt.Println(err)
		}
		return false
	} else {
		return true
	}
}

// Filter the rss feed items if it contains a specific string
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

// Parse the date of the rss feed in multiple formats/locations
func parseDate(item *gofeed.Item) (time.Time, error) {
	// Try the "published" field first
	if item.PublishedParsed != nil {
		return *item.PublishedParsed, nil
	}

	// Try the "updated" field next
	if item.UpdatedParsed != nil {
		return *item.UpdatedParsed, nil
	}

	// Try the "date" custom field
	date, ok := item.Custom["date"]
	if !ok {
		return time.Time{}, fmt.Errorf("no time field found in item")
	}

	// Try parsing the "date" field with two different layouts
	t, err := time.Parse(time.RFC1123, date)
	if err != nil {
		t, err = time.Parse("Mon, 2 Jan 2006 15:04:05 -0700", date)
		if err != nil {
			return time.Time{}, fmt.Errorf("error parsing time: %v", err)
		}
	}

	return t, nil
}
