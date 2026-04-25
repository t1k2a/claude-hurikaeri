import { strict as assert } from "assert";
import { test } from "node:test";
import * as http from "http";
import { sendWebhook } from "./webhook.js";

// Helper: start a simple HTTP server that returns the given status code
function startMockServer(statusCode: number): Promise<{ url: string; close: () => void }> {
  return new Promise((resolve) => {
    const server = http.createServer((_req, res) => {
      res.writeHead(statusCode);
      res.end();
    });
    server.listen(0, "127.0.0.1", () => {
      const addr = server.address() as { port: number };
      resolve({
        url: `http://127.0.0.1:${addr.port}`,
        close: () => server.close(),
      });
    });
  });
}

test("sendWebhook returns true on HTTP 200", async () => {
  const mock = await startMockServer(200);
  try {
    const result = await sendWebhook(mock.url, "test payload", {
      maxRetries: 1,
      retryDelayMs: 10,
    });
    assert.equal(result, true);
  } finally {
    mock.close();
  }
});

test("sendWebhook returns false after all retries on HTTP 500", async () => {
  const mock = await startMockServer(500);
  try {
    const result = await sendWebhook(mock.url, "test payload", {
      maxRetries: 2,
      retryDelayMs: 10,
    });
    assert.equal(result, false);
  } finally {
    mock.close();
  }
});

test("sendWebhook returns false when server is unreachable", async () => {
  const result = await sendWebhook("http://127.0.0.1:19999", "test", {
    maxRetries: 1,
    retryDelayMs: 10,
  });
  assert.equal(result, false);
});
