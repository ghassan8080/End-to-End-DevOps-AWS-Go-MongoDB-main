// Load testing script for Go Survey Application using k6.io
// 
// This script performs load testing against the application to evaluate
// performance under various load conditions.
// 
// Usage:
//   k6 run k6.example.js --duration 10m --vus 50

import http from 'k6/http';
import { check, sleep } from 'k6';

// Configuration options for the load test
export const options = {
  stages: [
    { duration: '30s', target: 100 },   // Ramp up to 100 users
    { duration: '1m30s', target: 150 }, // Ramp up to 150 users
    { duration: '5m', target: 250 },    // Stay at 250 users
  ],
};

export default function () {
  // Replace with your actual application URL
  const baseUrl = 'http://goapp.YOUR_DOMAIN.com';
  
  // Make a GET request to the application
  const res = http.get(baseUrl);
  
  // Check that the response status is 200
  check(res, {
    'status was 200': (r) => r.status == 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
  
  // Pause for 1 second between iterations
  sleep(1);
}