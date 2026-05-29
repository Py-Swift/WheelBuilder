const PUBLIC_BUCKET_URL = "https://pub-352a0bb435aa434b951d3503ac8fc533.r2.dev";

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    // Root simple index — list all packages derived from uploaded wheels
    if (path === "/simple" || path === "/simple/") {
      const objects = await listAll(env.BUCKET, "packages/");
      const packages = new Set();
      for (const obj of objects) {
        const filename = obj.key.slice("packages/".length);
        if (filename.endsWith(".whl")) {
          packages.add(normalizeWheelName(filename));
        }
      }
      const links = [...packages].sort()
        .map(pkg => `    <a href="/simple/${pkg}/">${pkg}</a><br>`)
        .join("\n");
      return html(
        `<!DOCTYPE html>\n<html>\n  <head><title>Simple Index</title></head>\n` +
        `  <body>\n${links}\n  </body>\n</html>\n`
      );
    }

    // Per-package index — /simple/<package>/
    const pkgMatch = path.match(/^\/simple\/([^/]+)\/?$/);
    if (pkgMatch) {
      const pkgName = normalize(pkgMatch[1]);
      const objects = await listAll(env.BUCKET, "packages/");
      const files = [];
      for (const obj of objects) {
        const filename = obj.key.slice("packages/".length);
        if (filename.endsWith(".whl") && normalizeWheelName(filename) === pkgName) {
          files.push(filename);
        }
      }
      if (files.length === 0) return new Response("Not Found", { status: 404 });
      const links = files.sort()
        .map(fn => `    <a href="${PUBLIC_BUCKET_URL}/packages/${fn}">${fn}</a><br>`)
        .join("\n");
      return html(
        `<!DOCTYPE html>\n<html>\n  <head><title>Links for ${pkgName}</title></head>\n` +
        `  <body>\n    <h1>Links for ${pkgName}</h1>\n${links}\n  </body>\n</html>\n`
      );
    }

    return new Response("Not Found", { status: 404 });
  },
};

function html(body) {
  return new Response(body, { headers: { "Content-Type": "text/html" } });
}

function normalize(name) {
  return name.toLowerCase().replace(/[-_.]+/g, "-");
}

function normalizeWheelName(filename) {
  return normalize(filename.split("-")[0]);
}

async function listAll(bucket, prefix) {
  const objects = [];
  let cursor;
  do {
    const result = await bucket.list({ prefix, cursor, limit: 1000 });
    objects.push(...result.objects);
    cursor = result.truncated ? result.cursor : undefined;
  } while (cursor);
  return objects;
}
