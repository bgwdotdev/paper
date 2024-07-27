import gleam/float
import gleam/io
import gleam/list
import gleam/set
import gleam/string

pub fn start(spec: Spec(state)) -> Nil {
  let #(vw, vh) = window_size() |> io.debug
  let w = vw /. spec.width |> float.floor
  let h = vh /. spec.height |> float.floor
  let scale = float.min(w, h)
  let #(_canvas, ctx) = init_canvas(spec.id, spec.width, spec.height, scale)
  scale_canvas(ctx, scale, scale)

  init_resize(ctx, spec.width, spec.height) |> window_resize
  init_keys()
  let state = spec.init()
  let engine = init()
  draw_canvas(fn() { loop(state, ctx, spec, engine) })
}

fn loop(state: state, ctx: Context, spec: Spec(state), engine: Engine) -> Nil {
  // ENGINE
  let curr = now()
  let dt = curr -. engine.prev

  // APP
  case dt >=. 16.0 {
    True -> {
      // update
      let engine = Engine(..engine, prev: curr, frames: engine.frames +. 1.0)
      let state = spec.update(state)
      state |> spec.view() |> render(ctx)
      // debug
      case spec.debug {
        True -> {
          // frame timing
          string.inspect({ now() -. engine.begin } /. engine.frames)
          |> text(ctx, 10.0, 10.0, _)
          Nil
        }
        False -> Nil
      }
      // loop
      fn() { loop(state, ctx, spec, engine) } |> draw_canvas
    }
    False -> loop(state, ctx, spec, engine)
  }
}

fn init() -> Engine {
  Engine(prev: now(), begin: now(), end: now(), frames: 0.0)
}

type Engine {
  Engine(prev: Float, begin: Float, end: Float, frames: Float)
}

pub type Spec(state) {
  Spec(
    // The id of the canvas element to render to
    id: String,
    // The canvas width
    width: Float,
    // The canvas height
    height: Float,
    // Enables debugging features
    debug: Bool,
    // Creates the games first state
    init: fn() -> state,
    // Things to render onto the canvas
    view: fn(state) -> Draws,
    // The core game logic update loop
    update: fn(state) -> state,
  )
}

pub type Draws =
  List(Draw)

fn render(r: Draws, ctx: Context) -> Nil {
  clear_canvas(ctx)
  r |> list.each(fn(d) { d(ctx) })
}

pub type Canvas {
  Canvas(width: Float, height: Float)
}

pub type Context {
  Context(canvas: Canvas)
}

pub type Rec {
  Rec(x: Float, y: Float, width: Float, height: Float)
}

pub type Rect {
  Rect(x: Float, y: Float, width: Float, height: Float)
}

pub type RectImg

pub fn collision_recs(rec1: Rect, rec2: Rect) -> Bool {
  rec1.x <. rec2.x +. rec2.width
  && rec1.x +. rec1.width >. rec2.x
  && rec1.y <. rec2.y +. rec2.height
  && rec1.y +. rec1.height >. rec2.y
}

//
// CORE
//

@external(javascript, "./canvas.mjs", "window_size")
fn window_size() -> #(Float, Float)

@external(javascript, "./canvas.mjs", "window_resize")
fn window_resize(func: fn(e) -> Nil) -> Nil

fn init_resize(ctx: Context, cw: Float, ch: Float) -> fn(e) -> Nil {
  fn(_) {
    let #(vw, vh) = window_size()
    let w = vw /. cw |> float.floor
    let h = vh /. ch |> float.floor
    let scale = float.min(w, h)
    resize_canvas(ctx, cw *. scale, ch *. scale)
    scale_canvas(ctx, scale, scale)
    Nil
  }
}

@external(javascript, "./canvas.mjs", "init_canvas")
fn init_canvas(id: String, w: Float, h: Float, s: Float) -> #(Canvas, Context)

@external(javascript, "./canvas.mjs", "clear_canvas")
fn clear_canvas(ctx: Context) -> Nil

@external(javascript, "./canvas.mjs", "draw_canvas")
fn draw_canvas(draw: fn() -> Nil) -> Nil

@external(javascript, "./canvas.mjs", "resize_canvas")
fn resize_canvas(ctx: Context, w: Float, h: Float) -> Nil

@external(javascript, "./canvas.mjs", "scale_canvas")
fn scale_canvas(ctx: Context, x: Float, y: Float) -> Drawable

pub fn scale(x: Float, y: Float) -> Draw {
  fn(ctx) { scale_canvas(ctx, x, y) }
}

@external(javascript, "./canvas.mjs", "now")
fn now() -> Float

//
// INPUT
//

@external(javascript, "./canvas.mjs", "init_keydown")
fn init_keydown(func: fn(Event, Keys) -> Keys) -> Nil

@external(javascript, "./canvas.mjs", "init_keyup")
fn init_keyup(func: fn(Event, Keys) -> Keys) -> Nil

@external(javascript, "./canvas.mjs", "get_keys")
pub fn get_keys() -> Keys

type Event {
  Event(key: String)
}

type Keys =
  set.Set(String)

fn init_keys() -> Nil {
  key_set(True) |> init_keydown
  key_set(False) |> init_keyup
}

fn key_set(set: Bool) -> fn(Event, Keys) -> Keys {
  let do = fn(k, ks) {
    case set {
      True -> set.insert(ks, k)
      False -> set.delete(ks, k)
    }
  }
  fn(event: Event, keys: Keys) { do(event.key, keys) }
}

//
// DRAW METHODS
//

pub type Drawable

pub type Draw =
  fn(Context) -> Drawable

pub fn draw_rec(rect: Rect, color: String) -> Draw {
  fn(ctx) { rec(ctx, rect.x, rect.y, rect.width, rect.height, color) }
}

@external(javascript, "./canvas.mjs", "rec")
fn rec(
  ctx: Context,
  x: Float,
  y: Float,
  w: Float,
  h: Float,
  c: String,
) -> Drawable

pub fn draw_img(rect: Rect, image: Image) -> Draw {
  fn(ctx) { img(ctx, rect.x, rect.y, rect.width, rect.height, image) }
}

@external(javascript, "./canvas.mjs", "img")
fn img(
  ctx: Context,
  x: Float,
  y: Float,
  w: Float,
  h: Float,
  image: Image,
) -> Drawable

// TEXT 

pub fn draw_text(x: Float, y: Float, str: String) -> Draw {
  fn(ctx) { text(ctx, x, y, str) }
}

@external(javascript, "./canvas.mjs", "text")
fn text(ctx: Context, x: Float, y: Float, str: String) -> Drawable

@external(javascript, "./canvas.mjs", "measure_text")
pub fn measure_text(ctx: Context, str: String) -> Float

//
// ASSETS
//

pub type Image

@external(javascript, "./canvas.mjs", "image")
pub fn load_image(src: String) -> Image
