# Load Testing with k6

This directory contains load testing scripts for the Go Survey application using k6, a modern load testing tool.

## Table of Contents

- [Load Testing Purpose](#load-testing-purpose)
- [How to Run k6 Tests](#how-to-run-k6-tests)
- [Example Commands](#example-commands)
- [Interpreting Results](#interpreting-results)

---

## Load Testing Purpose

The k6 load tests are designed to:

1. **Evaluate Application Performance**: Measure response times under various load conditions
2. **Identify Bottlenecks**: Discover performance limitations before they affect users
3. **Validate Scalability**: Ensure the application can handle expected traffic
4. **Test Infrastructure**: Verify that Kubernetes and AWS resources can handle load
5. **Establish Baselines**: Create performance metrics for future comparisons

### Test Scenarios

The default load test simulates:
- Gradual ramp-up of virtual users
- Sustained load at peak levels
- HTTP GET requests to the application endpoint

---

## How to Run k6 Tests

### Prerequisites

1. **Install k6**:
   ```bash
   # macOS
   brew install k6
   
   # Linux
   sudo gpg -k
   sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
   echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
   sudo apt-get update
   sudo apt-get install k6
   
   # Windows
   # Download from https://k6.io/download/
   ```

2. **Ensure Application is Running**:
   ```bash
   # Check if application is accessible
   curl http://goapp.YOUR_DOMAIN/
   ```

### Running the Default Test

```bash
# From the repository root
cd tests/k6

# Run the default test
k6 run load-test.js
```

---

## Example Commands

### Basic Load Test

```bash
# Run with default configuration
k6 run load-test.js
```

### Custom Duration

```bash
# Run for 10 minutes
k6 run --duration 10m load-test.js
```

### Custom Virtual Users

```bash
# Run with 50 virtual users
k6 run --vus 50 load-test.js
```

### Output to File

```bash
# Save results to JSON
k6 run --out json=results.json load-test.js
```

### Custom Stages

Modify the `options` object in `load-test.js`:

```javascript
export const options = {
  stages: [
    { duration: '2m', target: 50 },   // Ramp up to 50 users
    { duration: '5m', target: 100 },  // Stay at 100 users
    { duration: '2m', target: 0 },    // Ramp down to 0
  ],
};
```

---

## Interpreting Results

### Key Metrics

After running a test, k6 will display several important metrics:

| Metric | Description | Good Value |
|--------|-------------|------------|
| `http_req_duration` | HTTP request duration | < 500ms (p95) |
| `http_reqs` | Total HTTP requests | Increases with load |
| `http_req_failed` | Failed HTTP requests | 0% |
| `vus` | Virtual Users | Matches configuration |
| `vus_max` | Max Virtual Users | Matches configuration |

### Understanding the Output

```
✓ status was 200

checks.........................: 100.00% ✓ 6000      ✗ 0
data_received..................: 1.2 MB  20 kB/s
data_sent......................: 720 kB  12 kB/s
http_req_blocked...............: avg=1.2ms  min=0.5µs  med=4µs    max=45ms   p(90)=5µs    p(95)=7µs    
http_req_connecting..........: avg=10ms   min=0s     med=0s     max=150ms  p(90)=0s     p(95)=0s     
http_req_duration.............: avg=150ms  min=50ms   med=120ms  max=500ms  p(90)=200ms  p(95)=250ms  
  { expected_response:true }...: avg=150ms  min=50ms   med=120ms  max=500ms  p(90)=200ms  p(95)=250ms  
http_req_failed................: 0.00%   ✓ 0        ✗ 6000
http_req_receiving.............: avg=5ms    min=10µs   med=2ms    max=50ms   p(90)=10ms   p(95)=15ms   
http_req_sending...............: avg=2ms    min=5µs    med=1ms    max=20ms   p(90)=3ms    p(95)=5ms    
http_req_tls_handshaking.......: avg=5ms    min=0s     med=0s     max=50ms   p(90)=0s     p(95)=0s     
http_req_waiting...............: avg=143ms  min=40ms   med=115ms  max=480ms  p(90)=190ms  p(95)=240ms  
http_reqs......................: 6000    100/s
iteration_duration.............: avg=152ms  min=50ms   med=122ms  max=500ms  p(90)=202ms  p(95)=252ms  
iterations.....................: 6000    100/s
vus............................: 50      min=50     max=50
vus_max........................: 50      min=50     max=50
```

### What to Look For

1. **Response Times**:
   - `http_req_duration` should remain stable under load
   - `p(95)` (95th percentile) is a good indicator of worst-case user experience
   - Sudden spikes indicate performance issues

2. **Success Rate**:
   - `http_req_failed` should be 0%
   - Any failures indicate issues with the application or infrastructure

3. **Throughput**:
   - `http_reqs` shows requests per second
   - Compare against your expected traffic patterns

4. **Resource Utilization**:
   - Monitor CPU, memory, and network metrics during tests
   - Check Kubernetes pod metrics with `kubectl top pods`

### Performance Benchmarks

For the Go Survey application:

| Metric | Target | Acceptable |
|--------|--------|-----------|
| Average Response Time | < 100ms | < 200ms |
| 95th Percentile | < 200ms | < 500ms |
| Error Rate | 0% | < 1% |
| Max Concurrent Users | 100+ | 50+ |

---

## Troubleshooting

### Test Failures

If tests fail:

1. **Verify Application is Running**:
   ```bash
   curl http://goapp.YOUR_DOMAIN/
   ```

2. **Check Kubernetes Pods**:
   ```bash
   kubectl get pods -n go-survey
   ```

3. **Review Application Logs**:
   ```bash
   kubectl logs -l app=go-app -n go-survey
   ```

### Poor Performance

If performance is poor:

1. **Check Resource Utilization**:
   ```bash
   kubectl top pods -n go-survey
   ```

2. **Review Horizontal Pod Autoscaler**:
   ```bash
   kubectl get hpa -n go-survey
   ```

3. **Check Database Performance**:
   ```bash
   # Connect to MongoDB
   kubectl exec -it <mongo-pod> -n go-survey -- mongo
   
   # Check performance
   db.serverStatus()
   ```

---

## Best Practices

1. **Run Tests Regularly**: Include load tests in your CI/CD pipeline
2. **Test in Staging**: Always test in a staging environment before production
3. **Monitor During Tests**: Watch application and infrastructure metrics
4. **Establish Baselines**: Document normal performance metrics
5. **Test Edge Cases**: Test failure scenarios and recovery
6. **Gradual Ramp-up**: Avoid sudden load spikes that don't reflect real traffic
7. **Clean Up After Tests**: Remove test data and reset the environment

---

## Additional Resources

- [k6 Documentation](https://k6.io/docs/)
- [k6 Examples](https://k6.io/docs/examples/)
- [Performance Testing Best Practices](https://k6.io/docs/test-types/load-testing/)