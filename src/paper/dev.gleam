import gleam/io
import gleam/string
import gleam/uri

pub fn main() {
  let name = gleam_toml_name()
  let index = index |> string.replace("<MODULE>", name)

  let server =
    serve(
      port: 8000,
      websocket: WebsocketOptions(open: fn(ws) { subscribe(ws, "reload") }),
      fetch: fn(req, server) {
        let name = url_path(req)
        case name |> uri.path_segments {
          ["ws"] ->
            case websocket_upgrade(server, req) {
              Ok(Nil) -> response("", 200)
              Error(Nil) -> response("upgrade failed", 500)
            }
          [] -> response_html(index)
          _ -> response_file("." <> name)
        }
      },
    )

  let _watcher =
    watcher("./src", fn(_, _filename) {
      build()
      publish(server, "reload", "")
      Nil
    })

  io.println(banner)
  io.println("listening on: http://localhost:8000")
  io.println("warning: this server is not safe for use in production")
  build()
  Nil
}

type WatchEventType

type FSWatcher

@external(javascript, "./dev_ffi", "watcher")
fn watcher(path: String, fun: fn(WatchEventType, String) -> Nil) -> FSWatcher

@external(javascript, "./dev_ffi", "build")
fn build_ffi() -> Result(Nil, Nil)

fn build() -> Nil {
  case build_ffi() {
    Ok(Nil) ->
      "\u{001b}[2K\u{001b}[1Gcompiled: [ \u{001b}[32m●\u{001b}[0m ]"
      |> io.print
    Error(Nil) ->
      "\u{001b}[2K\u{001b}[1Gcompiled: [ \u{001b}[31m●\u{001b}[0m ]"
      |> io.print
  }
}

type Request

type Server

type Response

type WebsocketOptions {
  WebsocketOptions(open: fn(Websocket) -> Nil)
}

type Websocket

type BunServer

@external(javascript, "./dev_ffi", "serve")
fn serve(
  port port: Int,
  websocket websocket: WebsocketOptions,
  fetch fetch: fn(Request, Server) -> Response,
) -> BunServer

@external(javascript, "./dev_ffi", "url_path")
fn url_path(request: Request) -> String

@external(javascript, "./dev_ffi", "websocket_upgrade")
fn websocket_upgrade(server: Server, request: Request) -> Result(Nil, Nil)

@external(javascript, "./dev_ffi", "subscribe")
fn subscribe(websocket: Websocket, topic: String) -> Nil

@external(javascript, "./dev_ffi", "publish")
fn publish(server: BunServer, topic: String, msg: String) -> Nil

@external(javascript, "./dev_ffi", "response")
fn response(msg: String, status: Int) -> Response

@external(javascript, "./dev_ffi", "response_file")
fn response_file(path: String) -> Response

@external(javascript, "./dev_ffi", "response_html")
fn response_html(fragment: String) -> Response

@external(javascript, "./dev_ffi", "gleam_toml_name")
fn gleam_toml_name() -> String

const index = "<!DOCTYPE html>
<head>
<link rel='icon' type='image/svg+xml' href='data:image/svg+xml,%3Csvg xmlns=%27http://www.w3.org/2000/svg%27 viewBox=%270 0 16 16%27%3E%3Crect width=%2716%27 height=%2716%27 fill=%27%23000%27/%3E%3Cpath d=%27M6 4h5v1h1v4h-1v1H6V4zm1 1v4h3V5H7zm-1 5h1v4H6v-4z%27 fill=%27%23ffaff3%27/%3E%3C/svg%3E'>
<style>
  body {
    margin: 0 auto;
    background-color: black;
    width: 100vw;
    height: 100vh;
    display: grid;
    justify-content: center;
    align-content: center;
  }
  #canvas {
    <!--cursor: none; -->
  }
</style>
</head>
<body>
    <canvas id='canvas'></canvas>
    <script type='module'>

      const hotreload = await import(`./build/dev/javascript/<MODULE>/<MODULE>.mjs`);
      const update = await import(`./build/dev/javascript/<MODULE>/<MODULE>/update.mjs?t=${Date.now()}`);
      const game = {
        update: update.update,
        view: update.view
      }
      const hotupdate = (state, input) => {
        return game.update(state, input)
      }
      const hotview = (state) => {
        return game.view(state)
      }
      hotreload.main(hotupdate, hotview)

      async function hotPatch() {
        const update = await import(`./build/dev/javascript/<MODULE>/<MODULE>/update.mjs?t=${Date.now()}`);
        game.update = update.update;
        game.view = update.view;
      }
      const socket = new WebSocket('ws://localhost:8000/ws');
      socket.addEventListener('message', event => {
        hotPatch();
      });
    </script>
</body>
"

const banner = "
████▄  ▀▀█▄ ████▄ ▄█▀█▄ ████▄
██ ██ ▄█▀██ ██ ██ ██▄█▀ ██ ▀▀
████▀ ▀█▄██ ████▀ ▀█▄▄▄ ██
██          ██
▀▀          ▀▀
"
