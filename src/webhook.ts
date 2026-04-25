import { request as httpsRequest } from "https";
import { request as httpRequest } from "http";
import { URL } from "url";

interface WebhookPayload {
  text: string;
  [key: string]: unknown;
}

interface WebhookOptions {
  maxRetries?: number;
  retryDelayMs?: number;
}

/**
 * Sleep for a given number of milliseconds
 */
function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Send an HTTP POST request to a URL with a JSON payload
 */
function postJson(url: string, payload: WebhookPayload): Promise<number> {
  return new Promise((resolve, reject) => {
    const parsedUrl = new URL(url);
    const body = JSON.stringify(payload);
    const options = {
      hostname: parsedUrl.hostname,
      port: parsedUrl.port || (parsedUrl.protocol === "https:" ? 443 : 80),
      path: parsedUrl.pathname + parsedUrl.search,
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(body),
      },
    };

    const reqFn = parsedUrl.protocol === "https:" ? httpsRequest : httpRequest;
    const req = reqFn(options, (res) => {
      resolve(res.statusCode ?? 0);
    });

    req.on("error", reject);
    req.write(body);
    req.end();
  });
}

/**
 * Send a standup report to a Webhook URL with retry on failure.
 * Returns true on success, false if all retries are exhausted.
 */
export async function sendWebhook(
  webhookUrl: string,
  markdownText: string,
  options: WebhookOptions = {}
): Promise<boolean> {
  const maxRetries = options.maxRetries ?? 3;
  const retryDelayMs = options.retryDelayMs ?? 2000;

  const payload: WebhookPayload = { text: markdownText };

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      const statusCode = await postJson(webhookUrl, payload);
      if (statusCode >= 200 && statusCode < 300) {
        return true;
      }
      console.error(
        `Webhook attempt ${attempt}/${maxRetries} failed with HTTP ${statusCode}`
      );
    } catch (err) {
      console.error(
        `Webhook attempt ${attempt}/${maxRetries} error: ${err instanceof Error ? err.message : String(err)}`
      );
    }

    if (attempt < maxRetries) {
      // Exponential backoff
      await sleep(retryDelayMs * Math.pow(2, attempt - 1));
    }
  }

  console.error(
    `Webhook delivery failed after ${maxRetries} attempts. URL: ${webhookUrl}`
  );
  return false;
}
