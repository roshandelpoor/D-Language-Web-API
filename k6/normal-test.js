import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 25 },  // Ramp up to 25 users in 30s
    { duration: '1m', target: 50 },   // Ramp up to 50 users in 1m
    { duration: '30s', target: 0 },   // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95% of requests should be below 500ms
    http_req_failed: ['rate<0.01'],    // Less than 1% of requests should fail
  },
};

const BASE_URL = 'http://nginx';

export default function () {
  // Test root endpoint
  const rootResponse = http.get(`${BASE_URL}/`);
  check(rootResponse, {
    'root status is 200': (r) => r.status === 200,
    'root has correct message': (r) => r.json('status') === 'running ...',
  });

  sleep(1);  // 1 second sleep between requests

  // Test run endpoint
  const runResponse = http.get(`${BASE_URL}/run`);
  check(runResponse, {
    'run status is 200': (r) => r.status === 200,
    'run has correct message': (r) => r.json('message') === 'everything is working',
  });

  sleep(1);  // 1 second sleep between requests
} 