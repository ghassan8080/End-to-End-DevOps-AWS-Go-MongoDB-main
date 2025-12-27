package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gorilla/mux"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type Answer struct {
	ID       string `json:"id,omitempty"`
	Answer_1 string `json:"answer1,omitempty"`
	Answer_2 string `json:"answer2,omitempty"`
	Answer_3 string `json:"answer3,omitempty"`
}

var client *mongo.Client

func main() {
	// Set up MongoDB connection
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	// Get server port from environment variable or use default
	serverPort := getEnv("SERVER_PORT", "8080")
	// Get MongoDB URI from environment variable or use default
	mongoURI := getEnv("MONGO_URI", "mongodb://localhost:27017")
	clientOptions := options.Client().ApplyURI(mongoURI)
	var err error
	client, err = mongo.Connect(ctx, clientOptions)
	if err != nil {
		log.Fatalf("Failed to connect to MongoDB: %v", err)
	}

	// Ping the MongoDB server to verify connection
	err = client.Ping(ctx, nil)
	if err != nil {
		log.Fatalf("Failed to ping MongoDB: %v", err)
	}

	router := mux.NewRouter()
	router.HandleFunc("/", GetQuestion).Methods("GET")
	router.HandleFunc("/", SubmitAnswer).Methods("POST")

	log.Printf("Starting server on port %s...", serverPort)
	log.Fatal(http.ListenAndServe(":"+serverPort, router))
}

// Get environment variable or fallback to default
func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

// Question 1
func GetQuestion(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode("What is your favorite programming language framework ?")
}

// Answer 1
func SubmitAnswer(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var answer Answer
	if err := json.NewDecoder(r.Body).Decode(&answer); err != nil {
		log.Printf("Error decoding request body: %v", err)
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(map[string]string{"error": "Invalid request body"})
		return
	}

	log.Printf("answer.Answer_1: %v", answer.Answer_1)
	log.Printf("answer.Answer_2: %v", answer.Answer_2)
	log.Printf("answer.Answer_3: %v", answer.Answer_3)

	collection := client.Database("surveyDB").Collection("answers")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	result, err := collection.InsertOne(ctx, bson.M{"Answer1": answer.Answer_1, "Answer2": answer.Answer_2, "Answer3": answer.Answer_3})
	if err != nil {
		log.Printf("Error inserting answer: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{"error": "Failed to save answer"})
		return
	}

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(result.InsertedID)
}
