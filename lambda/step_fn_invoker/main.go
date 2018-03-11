package main

import (
	"encoding/json"
	"log"
	"os"
	"strconv"

	"github.com/River-Island/gopkgs/aws/s3"
	"github.com/apex/go-apex/kinesis"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sfn"
	"github.com/eggsbenjamin/pipeline_spike/models"
	"github.com/pkg/errors"
)

var (
	sfnClient   *sfn.SFN
	s3Client    s3.Putter
	maxAttempts int
)

func init() {
	session := session.Must(session.NewSession())
	cfg := &aws.Config{}
	sfnClient = sfn.New(session, cfg)
	s3Client = s3.NewBasicClient(
		os.Getenv("S3_BUCKET"),
		os.Getenv("S3_REGION"),
		os.Getenv("S3_PREFIX"),
	)

	ma, err := strconv.Atoi(os.Getenv("MAX_ATTEMPTS"))
	if err != nil {
		maxAttempts = 3
		log.Printf("Using default 'MAX_ATTEMPTS': %d", maxAttempts)
		return
	}
	maxAttempts = ma
}

func Handler(event *kinesis.Event) error {
	for _, record := range event.Records {
		var order *models.Order
		if err := json.Unmarshal(record.Kinesis.Data, &order); err != nil {
			return err
		}

		if order.Attempt >= maxAttempts {
			if err := s3Client.Put(record.EventID, record.Kinesis.Data); err != nil {
				return err
			}

			log.Printf("max attempts exceeded for order: %q", order.ID)
			return nil
		}

		if _, err := sfnClient.StartExecution(&sfn.StartExecutionInput{
			Input:           aws.String(string(record.Kinesis.Data)),
			StateMachineArn: aws.String(os.Getenv("STEP_FN_ARN")),
		}); err != nil {
			return errors.Wrap(err, "step fn invocation error")
		}
	}

	return nil
}

func main() {
	lambda.Start(Handler)
}
