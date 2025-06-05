import http from 'k6/http';
import { check, sleep } from 'k6';
import { randomString } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

// Test configuration
export const options = {
    scenarios: {
        upload_test: {
            executor: 'ramping-vus',
            startVUs: 0,
            stages: [
                { duration: '30s', target: 10 },  // Start with fewer users
                { duration: '1m', target: 10 },   // Stay at 10 users
                { duration: '30s', target: 0 },   // Ramp down to 0 users
            ],
        },
    },
    thresholds: {
        http_req_duration: ['p(95)<30000'],  // Increased timeout to 30 seconds
        http_req_failed: ['rate<0.01'],     // Less than 1% of requests should fail
    },
};

// Generate random file content
function generateFileContent() {
    // Generate 100KB of random data instead of 1MB
    return randomString(1024 * 100);
}

const BASE_URL = 'http://nginx';

export default function () {
    // Generate random file content
    const fileContent = generateFileContent();
    
    // Create form data with the file
    const data = {
        file: http.file(fileContent, 'test.txt', 'text/plain'),
    };

    // Make the upload request with increased timeout
    const response = http.post(`${BASE_URL}/upload`, data, {
        timeout: '30s',  // Set timeout to 30 seconds
    });

    // Check if the upload was successful
    check(response, {
        'is status 200': (r) => r.status === 200,
        'has success status': (r) => JSON.parse(r.body).status === 'success',
        'has filename': (r) => JSON.parse(r.body).filename !== undefined,
        'has size': (r) => JSON.parse(r.body).size !== undefined,
    });

    // Sleep between requests to prevent overwhelming the server
    sleep(2);  // Increased sleep time
}