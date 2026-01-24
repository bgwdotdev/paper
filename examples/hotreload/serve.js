import { watch } from "fs";

const FOLDER = "./";

const server = Bun.serve({
  port: 8000,
  fetch(req, server) {
    const name = new URL(req.url).pathname;
    if (name === "/ws") {
      if (server.upgrade(req)) { return; }
      return new Response("upgrade failed", { status: 500 });
    } else {
      const filename =  (name === "/") ? "./public/index.html" : name
      const path = FOLDER + filename;
      const file = Bun.file(path);
      return new Response(file);
    }
  },
  websocket: {
    open(ws) { ws.subscribe("reload"); },
  },
  error() {
    console.log("error");
  },
});

const path = "./build/dev/javascript/hotreload/hotreload";
const watcher = watch(path, (event, filename) => {
  console.log(`file updated: ${filename}`);
  server.publish("reload", "");
});

console.log(`Listening on http://localhost:${server.port} ...`);
