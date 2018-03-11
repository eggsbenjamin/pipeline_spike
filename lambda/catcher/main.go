package main

import (
	"encoding/json"
	"os"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/kinesis"
	"github.com/eggsbenjamin/pipeline_spike/models"
)

var (
	kinesisClient = kinesis.New(session.Must(session.NewSession()), &aws.Config{})
)

func Handler(order *models.Order) error {
	order.Attempt++

	orderJSON, err := json.Marshal(order)
	if err != nil {
		return err
	}

	if _, err := kinesisClient.PutRecord(&kinesis.PutRecordInput{
		PartitionKey: aws.String(os.Getenv("PARTITION_KEY")),
		StreamName:   aws.String(os.Getenv("STREAM_NAME")),
		Data:         orderJSON,
	}); err != nil {
		return err
	}

	return nil
}

func main() {
	lambda.Start(Handler)
}
