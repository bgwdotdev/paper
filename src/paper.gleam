import gleam/io
import gleam/list
import gleam/set
import gleam/string

pub fn start(spec: Spec(state)) -> Nil {
  let #(_canvas, ctx) = init_canvas(spec.id, spec.width, spec.height)
  key_down()
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
      let engine = Engine(..engine, prev: curr, frames: engine.frames +. 1.0)
      let state = spec.update(state)
      state |> spec.view() |> render(ctx)
      // frame timing
      string.inspect({ now() -. engine.begin } /. engine.frames)
      |> text(ctx, 10.0, 10.0, _)

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
    width: Int,
    // The canvas height
    height: Int,
    // Creates the games first state
    init: fn() -> state,
    // Things to render onto the canvas
    view: fn(state) -> Draws,
    // The core game logic update loop
    update: fn(state) -> state,
  )
}

pub type Draws =
  List(D)

pub type Draw {
  Rec(x: Float, y: Float, width: Float, height: Float)
  Img
}

fn render(r: Draws, ctx: Context) -> Nil {
  clear_canvas(ctx)
  r |> list.each(fn(d) { d(ctx) })
}

pub type Canvas {
  Canvas(width: Int, height: Int)
}

pub type Context {
  Context
}

pub type Rect {
  Rect(x: Float, y: Float, width: Float, height: Float, color: String)
}

pub fn collision_recs(rec1: Rect, rec2: Rect) -> Bool {
  rec1.x <. rec2.x +. rec2.width
  && rec1.x +. rec1.width >. rec2.x
  && rec1.y <. rec2.y +. rec2.height
  && rec1.y +. rec1.height >. rec2.y
}

//
// CORE
//

@external(javascript, "./canvas.mjs", "init_canvas")
fn init_canvas(id: String, w: Int, h: Int) -> #(Canvas, Context)

@external(javascript, "./canvas.mjs", "clear_canvas")
fn clear_canvas(ctx: Context) -> Nil

@external(javascript, "./canvas.mjs", "draw_canvas")
fn draw_canvas(draw: fn() -> Nil) -> Nil

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

fn key_down() -> Nil {
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
  fn(event: Event, keys: Keys) {
    case event.key {
      "w" as k -> do(k, keys)
      "s" as k -> do(k, keys)
      "a" as k -> do(k, keys)
      "d" as k -> do(k, keys)
      _ -> keys
    }
  }
}

//
// DRAW METHODS
//

pub type Drawable

pub type D =
  fn(Context) -> Drawable

pub fn draw_rec(rect: Rect) -> D {
  fn(ctx) { rec(ctx, rect.x, rect.y, rect.width, rect.height, rect.color) }
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

pub fn draw_text(x: Float, y: Float, str: String) -> D {
  fn(ctx) { text(ctx, x, y, str) }
}

@external(javascript, "./canvas.mjs", "text")
fn text(ctx: Context, x: Float, y: Float, str: String) -> Drawable
