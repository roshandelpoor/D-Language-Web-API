import http from 'k6/http';
export default function () {
  // Just sleep to keep the container alive
  http.get('http://localhost');
  sleep(600);
}