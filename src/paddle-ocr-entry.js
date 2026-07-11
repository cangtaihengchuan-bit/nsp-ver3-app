import * as paddleOcr from "@paddle-js-models/ocr";

let initPromise = null;

function modelPaths(options = {}) {
  const basePath = options.basePath || "./vendor/paddleocr";
  return {
    det: options.detModelPath || `${basePath}/det/model.json`,
    rec: options.recModelPath || `${basePath}/rec/model.json`
  };
}

async function ensureInitialized(options = {}) {
  if (!initPromise) {
    const paths = modelPaths(options);
    initPromise = paddleOcr.init(paths.det, paths.rec);
  }
  return initPromise;
}

function loadImage(source) {
  if (source instanceof HTMLImageElement) return Promise.resolve(source);
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(source);
    const image = new Image();
    image.onload = () => {
      URL.revokeObjectURL(url);
      resolve(image);
    };
    image.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error("画像を読み込めませんでした。"));
    };
    image.src = url;
  });
}

async function recognize(source, options = {}) {
  const startedAt = performance.now();
  await ensureInitialized(options);
  const image = await loadImage(source);
  const result = await paddleOcr.recognize(image, options.drawOptions);
  const text = Array.isArray(result?.text) ? result.text.join("\n") : String(result?.text || "");
  return {
    engine: "paddle",
    durationMs: Math.round(performance.now() - startedAt),
    text,
    raw: result
  };
}

window.NspPaddleOcr = {
  ensureInitialized,
  recognize
};
