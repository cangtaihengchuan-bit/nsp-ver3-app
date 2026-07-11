import fs from "node:fs/promises";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright-core";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(__dirname, "..");
const expectedPath = path.join(rootDir, "test_data", "receipt_expected.json");
const testImageDir = path.join(rootDir, "test_images");
const reportsDir = path.join(rootDir, "reports");
const edgePath = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe";

const mimeTypes = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".dat": "application/octet-stream",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".png": "image/png",
  ".svg": "image/svg+xml"
};

function startServer() {
  const server = http.createServer(async (request, response) => {
    try {
      const url = new URL(request.url || "/", "http://127.0.0.1");
      const pathname = decodeURIComponent(url.pathname === "/" ? "/household.html" : url.pathname);
      const filePath = path.resolve(rootDir, `.${pathname}`);
      if (!filePath.startsWith(rootDir)) {
        response.writeHead(403);
        response.end("Forbidden");
        return;
      }
      const data = await fs.readFile(filePath);
      response.writeHead(200, { "Content-Type": mimeTypes[path.extname(filePath)] || "application/octet-stream" });
      response.end(data);
    } catch {
      response.writeHead(404);
      response.end("Not found");
    }
  });
  return new Promise((resolve) => {
    server.listen(0, "127.0.0.1", () => {
      const address = server.address();
      resolve({ server, origin: `http://127.0.0.1:${address.port}` });
    });
  });
}

function countAmountHits(actualAmounts, expectedAmounts) {
  const rest = [...actualAmounts];
  let hits = 0;
  for (const expected of expectedAmounts) {
    const index = rest.indexOf(expected);
    if (index >= 0) {
      hits += 1;
      rest.splice(index, 1);
    }
  }
  return hits;
}

function scoreParsed(parsed, expected) {
  const actualAmounts = (parsed.items || []).map((item) => Number(item.amount)).filter(Boolean);
  const amountHits = countAmountHits(actualAmounts, expected.itemAmounts);
  const itemRecall = expected.itemAmounts.length ? amountHits / expected.itemAmounts.length : 0;
  const dateHit = parsed.date === expected.date;
  const totalHit = Number(parsed.total) === expected.total;
  const score = ((dateHit ? 1 : 0) + (totalHit ? 1 : 0) + itemRecall) / 3;
  return {
    dateHit,
    totalHit,
    amountHits,
    expectedItemCount: expected.itemAmounts.length,
    actualItemCount: actualAmounts.length,
    itemRecall: Number(itemRecall.toFixed(3)),
    score: Number(score.toFixed(3))
  };
}

async function run() {
  const expected = JSON.parse(await fs.readFile(expectedPath, "utf8"));
  await fs.access(testImageDir);
  await fs.mkdir(reportsDir, { recursive: true });
  const { server, origin } = await startServer();
  const browser = await chromium.launch({
    headless: true,
    executablePath: edgePath
  });
  const page = await browser.newPage();
  page.setDefaultTimeout(120000);
  const results = {
    createdAt: new Date().toISOString(),
    branch: process.env.GIT_BRANCH || "",
    engines: ["tesseract", "paddle"],
    cases: []
  };

  try {
    await page.goto(`${origin}/household.html?view=receipt`);
    await page.waitForFunction(() => typeof window.parseReceiptText === "function");
    await page.waitForFunction(() => typeof window.Tesseract?.recognize === "function");
    await page.waitForFunction(() => typeof window.NspPaddleOcr?.recognize === "function");

    for (const receipt of expected) {
      const imagePath = `/test_images/${receipt.file}`;
      const caseResult = { file: receipt.file, expected: receipt, engines: {} };
      for (const engine of results.engines) {
        const outcome = await page.evaluate(async ({ imagePath, engine }) => {
          const response = await fetch(imagePath);
          const blob = await response.blob();
          const file = new File([blob], imagePath.split("/").pop(), { type: blob.type || "image/jpeg" });
          const startedAt = performance.now();
          let text = "";
          if (engine === "tesseract") {
            const result = await window.Tesseract.recognize(file, "jpn+eng", {
              workerPath: "./vendor/tesseract/worker.min.js",
              corePath: "./vendor/tesseract/tesseract-core-simd-lstm.wasm.js",
              langPath: "./vendor/tesseract/lang"
            });
            text = result?.data?.text || "";
          } else {
            const result = await window.NspPaddleOcr.recognize(file);
            text = result.text || "";
          }
          const durationMs = Math.round(performance.now() - startedAt);
          const parsed = window.parseReceiptText(text);
          return { durationMs, text, parsed };
        }, { imagePath, engine });
        caseResult.engines[engine] = {
          durationMs: outcome.durationMs,
          parsed: outcome.parsed,
          score: scoreParsed(outcome.parsed, receipt),
          textPreview: outcome.text.slice(0, 1000)
        };
      }
      results.cases.push(caseResult);
      console.log(`${receipt.file}: Tesseract ${caseResult.engines.tesseract.durationMs}ms score ${caseResult.engines.tesseract.score.score}, Paddle ${caseResult.engines.paddle.durationMs}ms score ${caseResult.engines.paddle.score.score}`);
    }

    results.summary = {};
    for (const engine of results.engines) {
      const engineCases = results.cases.map((item) => item.engines[engine]);
      const avgDurationMs = engineCases.reduce((total, item) => total + item.durationMs, 0) / engineCases.length;
      const avgScore = engineCases.reduce((total, item) => total + item.score.score, 0) / engineCases.length;
      const dateHits = engineCases.filter((item) => item.score.dateHit).length;
      const totalHits = engineCases.filter((item) => item.score.totalHit).length;
      const amountHits = engineCases.reduce((total, item) => total + item.score.amountHits, 0);
      const expectedItems = engineCases.reduce((total, item) => total + item.score.expectedItemCount, 0);
      results.summary[engine] = {
        avgDurationMs: Math.round(avgDurationMs),
        avgScore: Number(avgScore.toFixed(3)),
        dateHits,
        totalHits,
        amountHits,
        expectedItems,
        itemRecall: Number((amountHits / expectedItems).toFixed(3))
      };
    }

    const reportPath = path.join(reportsDir, `ocr-benchmark-${Date.now()}.json`);
    await fs.writeFile(reportPath, JSON.stringify(results, null, 2), "utf8");
    console.log(`report: ${reportPath}`);
  } finally {
    await browser.close();
    await new Promise((resolve) => server.close(resolve));
  }
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
