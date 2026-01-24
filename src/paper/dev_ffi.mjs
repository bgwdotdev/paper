import { Ok, Error } from "../gleam.mjs"
import config from "../../../../../gleam.toml"
import { watch } from "fs"

export function serve(port, websocket, fetch) {
  return Bun.serve({port: port, websocket: websocket, fetch: fetch});
}

export function file(path) {
  return Bun.file(path);
}

export function url_path(req) {
  return new URL(req.url).pathname;
}

export function websocket_upgrade(server, req) {
  return server.upgrade(req) ? new Ok(undefined) : new Error(undefined);
}

export function subscribe(websocket, topic) {
  return websocket.subscribe(topic);
}

export function publish(server, topic, msg) {
  return server.publish(topic, msg);
}

export function response(msg, status) {
  return new Response(msg, { status: status });
}

export function response_file(path) {
  return new Response(Bun.file(path));
}

export function response_html(fragment) {
  return new Response(fragment, { headers: { "Content-Type": "text/html" } });
}

export function gleam_toml_name() {
  return config.name;
}

export function watcher(path, fun) {
  return watch(path, { recursive: true }, fun);
}

export function build() {
  return Bun.spawnSync(["gleam", "build"]);
}
