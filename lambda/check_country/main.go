package main

import (
	"fmt"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/eggsbenjamin/pipeline_spike/models"
)

type ErrInvalidCountryCode struct {
	code string
}

func (e ErrInvalidCountryCode) Error() string {
	return fmt.Sprintf("Invalid country code: %s", e.code)
}

func Handler(order *models.Order) (*models.Order, error) {
	switch order.CountryCode {
	case "GB":
		return order, nil
	case "PANIC":
		panic("ARGH!")
	default:
		return nil, ErrInvalidCountryCode{order.CountryCode}
	}
}

func main() {
	lambda.Start(Handler)
}
