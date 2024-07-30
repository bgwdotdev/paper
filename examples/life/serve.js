const FOLDER = "./public";

const server = Bun.serve({
  port: 8000,
  fetch(req) {
    const name = new URL(req.url).pathname;
    const filename =  (name === "/") ? "/index.html" : name
    const path = FOLDER + filename;
    const file = Bun.file(path);
    return new Response(file);
  },
  error() {
    console.log("error");
  },
});

console.log(`Listening on http://localhost:${server.port} ...`);
