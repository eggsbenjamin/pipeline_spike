package main

import (
	"encoding/json"
	"os"

	"github.com/River-Island/gopkgs/aws/s3"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/eggsbenjamin/pipeline_spike/models"
)

var s3Client s3.Putter

func init() {
	s3Client = s3.NewBasicClient(
		os.Getenv("S3_BUCKET"),
		os.Getenv("S3_REGION"),
		os.Getenv("S3_PREFIX"),
	)
}

func Handler(order *models.Order) error {
	orderJSON, err := json.Marshal(order)
	if err != nil {
		return err
	}

	if err := s3Client.Put(order.ID, orderJSON); err != nil {
		return err
	}

	return nil
}

func main() {
	lambda.Start(Handler)
}
