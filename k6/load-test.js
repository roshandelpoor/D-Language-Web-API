import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 2500 },  // Ramp up to 2500 users in 30s
    { duration: '30s', target: 5000 },  // Ramp up to 5000 users in next 30s
    { duration: '30s', target: 0 },     // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<1000'], // 95% of requests should be below 1s
    http_req_failed: ['rate<0.01'],    // Less than 1% of requests should fail
  },
};

const BASE_URL = 'http://d_app';

export default function () {
  // Test root endpoint
  const rootResponse = http.get(`${BASE_URL}/`);
  check(rootResponse, {
    'root status is 200': (r) => r.status === 200,
    'root has correct message': (r) => r.json('status') === 'running ...',
  });

  sleep(0.1);  // Small sleep between requests

  // Test run endpoint
  const runResponse = http.get(`${BASE_URL}/run`);
  check(runResponse, {
    'run status is 200': (r) => r.status === 200,
    'run has correct message': (r) => r.json('message') === 'everything is working',
  });

  sleep(0.1);  // Small sleep between requests
} 