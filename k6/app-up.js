import http from 'k6/http';

const BASE_URL = 'http://nginx';

export default function () {
  // Just sleep to keep the container alive
  http.get(`${BASE_URL}/`);
  sleep(600);
}