package models

type Order struct {
	ID          string `json:"id"`
	CountryCode string `json:"country_code"`
	Attempt     int    `json:"attempt"`
}
