import http from "k6/http";
import { sleep } from "k6";
import { check } from "k6";
import { Trend, Counter } from "k6/metrics";
import exec from "k6/execution";

export const options = {
  scenarios: {
    progressive_load: {
      executor: "ramping-vus",
      startVUs: 0,
      stages: [
        { duration: "10s", target: 2_000 }, // Ramp to 4K users
        { duration: "3000s", target: 2_000 }, // Hold at 4K users (50 minutes)
        { duration: "10s", target: 0 }, // Ramp down
      ],
    },
  },
  thresholds: {
    http_req_duration: ["p(95)<100"], // 95% under 100ms
  },
};

// Phoenix runs on port 4000 by default
const BASE_URL = __ENV.BASE_URL || "http://localhost:4000";
const itemIds = [1, 2, 3, 4, 5, 6, 7];

// Custom metrics for the plateau
const plateau4k = new Trend("http_req_duration_4k");
const requests4k = new Counter("http_reqs_4k");

// Global JWT cookie for this VU
let jwtCookie = null;

export default function () {
  // Get a real JWT token from server if we don't have one
  if (!jwtCookie) {
    const response = http.get(`${BASE_URL}/`, { timeout: "30s" });
    const cookieHeader = response.headers["Set-Cookie"];
    if (cookieHeader) {
      const match = cookieHeader.match(/jwt_token=([^;]+)/);
      if (match) {
        jwtCookie = match[1];
      }
    }

    // If still no cookie, something is wrong
    if (!jwtCookie) {
      console.error("Failed to get JWT cookie from Phoenix server");
      return;
    }
  }

  sleep(0.1);

  // Determine current stage using k6 execution context elapsed time
  const elapsedMs = Date.now() - exec.scenario.startTime;
  const elapsedSeconds = elapsedMs / 1000;

  let currentStage = "none";
  // 10-3010s: 4K plateau (10s ramp + 3000s hold)
  if (elapsedSeconds >= 10 && elapsedSeconds <= 3010)
    currentStage = "plateau4k";

  const randomItemId = itemIds[Math.floor(Math.random() * itemIds.length)];

  // Headers with current JWT as cookie + realistic browser headers
  const headers = () => ({
    Cookie: `jwt_token=${jwtCookie}`,
    "Content-Type": "application/json",
    "User-Agent":
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    Accept:
      "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
    "Accept-Encoding": "gzip, deflate, br",
    DNT: "1",
    Connection: "keep-alive",
    "Upgrade-Insecure-Requests": "1",
    "Sec-Fetch-Dest": "document",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-Site": "none",
    "Cache-Control": "max-age=0",
  });

  // 1. Add item to cart
  let response = http.post(`${BASE_URL}/api/cart/add/${randomItemId}`, null, {
    headers: headers(),
    timeout: "30s",
    insecureSkipTLSVerify: true,
  });

  // Record metrics only during plateau
  if (currentStage === "plateau4k") {
    plateau4k.add(response.timings.duration);
    requests4k.add(1);
  }

  check(response, {
    "add to cart status 200": (r) => r.status === 200,
  });

  sleep(0.1);

  // 2. Remove from cart
  response = http.del(`${BASE_URL}/api/cart/remove/${randomItemId}`, null, {
    headers: headers(),
    timeout: "30s",
  });

  // Record metrics for remove request too
  if (currentStage === "plateau4k") {
    plateau4k.add(response.timings.duration);
    requests4k.add(1);
  }

  check(response, {
    "remove from cart status 200": (r) => r.status === 200,
  });

  sleep(0.1);
}

export function handleSummary(data) {
  const metrics = data.metrics;

  // Calculate requests per second for the plateau
  const plateau4kReqs = metrics.http_reqs_4k?.values?.count || 0;

  // Plateau duration (3000s = 50 minutes)
  const reqs4kPerSec = plateau4kReqs / 3000;
  const totalMillionReqs = plateau4kReqs / 1000000;

  console.log(`
=== PHOENIX 50-MINUTE ENDURANCE TEST ===
📊 PLATEAU (4K VUs - 50 minutes):
  Requests: ${plateau4kReqs.toLocaleString()}
  Million Requests: ${totalMillionReqs.toFixed(1)}M
  Req/s: ${reqs4kPerSec.toFixed(0)}
  Avg Response Time: ${
    metrics.http_req_duration_4k?.values?.avg?.toFixed(2) || "N/A"
  }ms
  95th Percentile: ${
    metrics.http_req_duration_4k?.values?.["p(95)"]?.toFixed(2) || "N/A"
  }ms

=== PHOENIX OVERALL RESULTS ===
Peak VUs: ${metrics.vus_max.values.max}
Total Requests: ${metrics.http_reqs.values.count.toLocaleString()}
Failed Requests: ${(metrics.http_req_failed.values.rate * 100).toFixed(2)}%
Overall Requests/sec: ${metrics.http_reqs.values.rate.toFixed(1)} req/s
Avg Response Time: ${metrics.http_req_duration.values.avg.toFixed(2)}ms
95th Percentile: ${metrics.http_req_duration.values["p(95)"].toFixed(2)}ms
`);
}
