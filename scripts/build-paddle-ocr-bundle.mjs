import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import * as esbuild from "esbuild";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(__dirname, "..");

const aliases = new Map([
  ["@paddle-js-models/ocr", path.join(rootDir, "node_modules", "@paddle-js-models", "ocr", "lib", "index.esm.js")],
  ["@paddlejs/paddlejs-core", path.join(rootDir, "node_modules", "@paddlejs", "paddlejs-core", "lib", "index.js")],
  ["@paddlejs/paddlejs-backend-webgl", path.join(rootDir, "node_modules", "@paddlejs", "paddlejs-backend-webgl", "lib", "index.js")],
  ["@paddlejs-mediapipe/opencv", path.join(rootDir, "node_modules", "@paddlejs-mediapipe", "opencv", "lib", "opencv.js")],
  ["js-clipper", path.join(rootDir, "node_modules", "js-clipper", "clipper.js")],
  ["number-precision", path.join(rootDir, "node_modules", "number-precision", "build", "index.es.js")],
  ["d3-polygon", path.join(rootDir, "node_modules", "d3-polygon", "src", "index.js")],
  ["fs", path.join(rootDir, "src", "browser-empty.js")],
  ["path", path.join(rootDir, "src", "browser-empty.js")],
  ["crypto", path.join(rootDir, "src", "browser-empty.js")]
]);

const fixedResolvePlugin = {
  name: "fixed-resolve",
  setup(build) {
    build.onResolve({ filter: /.*/ }, (args) => {
      if (aliases.has(args.path)) {
        return { path: aliases.get(args.path) };
      }
      if (args.path.startsWith(".") || path.isAbsolute(args.path)) {
        const resolved = path.resolve(args.resolveDir || rootDir, args.path);
        if (fs.existsSync(resolved)) return { path: resolved };
        if (fs.existsSync(`${resolved}.js`)) return { path: `${resolved}.js` };
      }
      return null;
    });
  }
};

await esbuild.build({
  stdin: {
    contents: fs.readFileSync(path.join(rootDir, "src", "paddle-ocr-entry.js"), "utf8"),
    resolveDir: rootDir,
    sourcefile: "src/paddle-ocr-entry.js"
  },
  bundle: true,
  format: "iife",
  globalName: "NspPaddleOcrBundle",
  outfile: path.join(rootDir, "vendor", "paddle-ocr.bundle.js"),
  plugins: [fixedResolvePlugin]
});
