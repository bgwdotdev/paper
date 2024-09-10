import gleam/dict
import gleam/dynamic
import gleam/float
import gleam/int
import gleam/io

//import gleam/json
import gleam/list
import gleam/option.{type Option, None}
import gleam/result
import gleam/set
import gleam/string

pub type Spec(state) {
  Spec(
    /// the id of the canvas element to render to
    id: String,
    /// the canvas width
    width: Float,
    /// the canvas height
    height: Float,
    /// enables canvas image smoothing
    /// this should typically be False for pixel art
    ///
    /// https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API/Tutorial/Using_images#controlling_image_scaling_behavior
    smooth: Bool,
    /// enables debugging features
    debug: Bool,
    /// creates the games first state
    init: fn() -> state,
    /// things to render onto the canvas
    view: fn(state) -> Draws,
    /// the core game logic update loop
    update: fn(state, Input) -> state,
  )
}

pub fn start(spec: Spec(state)) -> Nil {
  let #(vw, vh) = window_size()
  let w = vw /. spec.width |> float.floor
  let h = vh /. spec.height |> float.floor
  let scale = float.min(w, h)
  let #(_canvas, ctx) =
    init_canvas(spec.id, spec.width, spec.height, scale, spec.smooth)
  scale_canvas(ctx, scale, scale)

  init_resize(ctx, spec.width, spec.height) |> window_resize
  init_keys()
  init_mouse()
  let state = spec.init()
  let engine = init()
  draw_canvas(fn() { loop(state, ctx, spec, engine) })
}

pub opaque type Canvas {
  Canvas(width: Float, height: Float)
}

pub opaque type Context {
  Context(canvas: Canvas)
}

// manages the game asset first loading state
type Status {
  Loading
  Loaded
  Failed(List(String))
}

//
// ENGINE
//

type Engine {
  Engine(
    prev: Float,
    begin: Float,
    end: Float,
    frames: Float,
    input: Input,
    asset: Status,
  )
}

fn init() -> Engine {
  Engine(
    prev: now(),
    begin: now(),
    end: now(),
    frames: 0.0,
    input: Input(set.new(), set.new(), dict.new(), dict.new()),
    asset: Loading,
  )
}

fn loop(state: state, ctx: Context, spec: Spec(state), engine: Engine) -> Nil {
  let curr = now()
  let dt = curr -. engine.prev

  let engine = status(engine)

  case dt >=. 16.0, engine.asset {
    False, _ -> loop(state, ctx, spec, engine)
    True, Loading -> {
      // spinner
      clear_canvas(ctx)
      let x = curr |> float.round()
      x / 500 % 4
      |> string.repeat(".", _)
      |> string.append("loading", _)
      |> text(ctx, 10.0, 10.0, _, "white")
      fn() { loop(state, ctx, spec, engine) } |> draw_canvas
    }
    True, Failed(errors) -> {
      // error
      clear_canvas(ctx)
      ["failed to load: \n", ..errors]
      |> string.join("\n")
      |> text(ctx, 10.0, 10.0, _, "white")
      fn() { loop(state, ctx, spec, engine) } |> draw_canvas
    }
    True, Loaded -> {
      // update
      let scale = window_scale(spec.width, spec.height)
      let input =
        Input(
          keys: get_keys(),
          prev: engine.input.keys,
          mouse: get_mouse_scale(scale),
          mouse_prev: engine.input.mouse,
        )
      let engine =
        Engine(..engine, prev: curr, frames: engine.frames +. 1.0, input: input)
      let state = spec.update(state, input)
      state |> spec.view() |> render(ctx)
      // debug
      case spec.debug {
        True -> {
          // frame timing
          string.inspect({ now() -. engine.begin } /. engine.frames)
          |> text(ctx, 10.0, 10.0, _, "red")
          Nil
        }
        False -> Nil
      }
      // loop
      io.debug(get_mouse())
      fn() { loop(state, ctx, spec, engine) } |> draw_canvas
    }
  }
}

fn status(engine: Engine) {
  case engine.asset {
    Loading -> {
      case asset_status() {
        0 -> Engine(..engine, asset: Loaded)
        x if x < 0 -> Engine(..engine, asset: asset_failed() |> Failed)
        _ -> engine
      }
    }
    Loaded -> engine
    Failed(errors) -> todo as "draw error?"
  }
}

pub type Rect {
  Rect(x: Float, y: Float, width: Float, height: Float)
}

pub type Vec2 {
  Vec2(x: Float, y: Float)
}

// checks if two rectangles overlap
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
    let scale = window_scale(cw, ch)
    resize_canvas(ctx, cw *. scale, ch *. scale)
    scale_canvas(ctx, scale, scale)
    Nil
  }
}

fn window_scale(cw: Float, ch: Float) -> Float {
  let #(vw, vh) = window_size()
  let w = vw /. cw |> float.floor
  let h = vh /. ch |> float.floor
  float.min(w, h)
}

@external(javascript, "./canvas.mjs", "init_canvas")
fn init_canvas(
  id: String,
  w: Float,
  h: Float,
  s: Float,
  smooth: Bool,
) -> #(Canvas, Context)

@external(javascript, "./canvas.mjs", "create_canvas")
fn create_canvas(w: Float, h: Float) -> Context

@external(javascript, "./canvas.mjs", "clear_canvas")
fn clear_canvas(ctx: Context) -> Nil

@external(javascript, "./canvas.mjs", "draw_canvas")
fn draw_canvas(draw: fn() -> Nil) -> Nil

@external(javascript, "./canvas.mjs", "resize_canvas")
fn resize_canvas(ctx: Context, w: Float, h: Float) -> Nil

@external(javascript, "./canvas.mjs", "scale_canvas")
fn scale_canvas(ctx: Context, x: Float, y: Float) -> Drawable

/// scale/zoom any draw calls made after this
pub fn scale(x: Float, y: Float) -> Draw {
  fn(ctx) { scale_canvas(ctx, x, y) }
}

@external(javascript, "./canvas.mjs", "now")
fn now() -> Float

//
// HELPERS
//

/// bool.guard but without the callback
pub fn guard(cond: Bool, then: a, or: a) -> a {
  case cond {
    True -> then
    False -> or
  }
}

//
// INPUT
//

pub opaque type Input {
  Input(keys: Keys, prev: Keys, mouse: Mouse, mouse_prev: Mouse)
}

// KEYBOARD

@external(javascript, "./canvas.mjs", "init_keydown")
fn init_keydown(func: fn(Event, Keys) -> Keys) -> Nil

@external(javascript, "./canvas.mjs", "init_keyup")
fn init_keyup(func: fn(Event, Keys) -> Keys) -> Nil

@external(javascript, "./canvas.mjs", "get_keys")
fn get_keys() -> Keys

/// check if a key is being held down
pub fn is_down(input: Input, key: String) -> Bool {
  let Input(keys, ..) = input
  set.contains(keys, key)
}

/// check if a key has been pressed once
pub fn is_pressed(input: Input, key: String) -> Bool {
  let Input(keys, prev, ..) = input
  case set.contains(prev, key), set.contains(keys, key) {
    False, True -> True
    _, _ -> False
  }
}

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

// MOUSE

type Mouse =
  dict.Dict(String, Vec2)

fn init_mouse() -> Nil {
  init_mousemove(mouse_set_move())
  mouse_set(True) |> init_mousedown
  mouse_set(False) |> init_mouseup
}

@external(javascript, "./canvas.mjs", "init_mousemove")
fn init_mousemove(func: fn(MouseEvent, Mouse) -> Mouse) -> Nil

@external(javascript, "./canvas.mjs", "init_mousedown")
fn init_mousedown(func: fn(MouseEvent, Mouse) -> Mouse) -> Nil

@external(javascript, "./canvas.mjs", "init_mouseup")
fn init_mouseup(func: fn(MouseEvent, Mouse) -> Mouse) -> Nil

@external(javascript, "./canvas.mjs", "get_offset")
fn get_offset(e: MouseEvent) -> Vec2

@external(javascript, "./canvas.mjs", "get_mouse")
fn get_mouse() -> Mouse

fn get_mouse_scale(scale: Float) -> Mouse {
  get_mouse()
  |> dict.map_values(fn(_k, v) { Vec2(x: v.x /. scale, y: v.y /. scale) })
}

type MouseEvent {
  MouseEvent(button: Int, x: Float, y: Float)
}

fn mouse_set(set: Bool) -> fn(MouseEvent, Mouse) -> Mouse {
  let do = fn(k, v, ks) {
    case set {
      True -> dict.insert(ks, k, v)
      False -> dict.delete(ks, k)
    }
  }
  fn(event: MouseEvent, mouse: Mouse) {
    let key = case event.button {
      0 -> "LMB"
      1 -> "MMB"
      2 -> "RMB"
      _ -> ""
    }
    let pos = get_offset(event)
    let pos = Vec2(x: event.x -. pos.x, y: event.y -. pos.y)
    do(key, pos, mouse)
  }
}

fn mouse_set_move() -> fn(MouseEvent, Mouse) -> Mouse {
  fn(event: MouseEvent, mouse: Mouse) {
    let pos = get_offset(event)
    let pos = Vec2(x: event.x -. pos.x, y: event.y -. pos.y)
    dict.insert(mouse, "CURSOR", pos)
  }
}

/// check if a mouse button is held down
pub fn is_held(input: Input, button: String) -> Option(Vec2) {
  dict.get(input.mouse, button) |> option.from_result
}

/// check if a mouse button has been clicked once
pub fn is_clicked(input: Input, button: String) -> Option(Vec2) {
  let pos = dict.get(input.mouse, button) |> option.from_result
  case
    dict.has_key(input.mouse_prev, button),
    dict.has_key(input.mouse, button)
  {
    False, True -> pos
    _, _ -> None
  }
}

pub fn pointer(input: Input) -> Vec2 {
  dict.get(input.mouse, "CURSOR") |> result.unwrap(Vec2(0.0, 0.0))
}

//
// DRAW METHODS
//

pub type Draws =
  List(Draw)

pub type Draw =
  fn(Context) -> Drawable

pub type Drawable

fn render(r: Draws, ctx: Context) -> Nil {
  clear_canvas(ctx)
  r |> list.each(fn(d) { d(ctx) })
}

/// draw a colored rectangle onto the canvas
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

/// draw an image onto the canvas
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

/// put text on the screen
pub fn draw_text(x: Float, y: Float, str: String, color: String) -> Draw {
  fn(ctx) { text(ctx, x, y, str, color) }
}

/// put text on the screen and center it relative to its own width
pub fn draw_text_center(x: Float, y: Float, str: String, color: String) -> Draw {
  fn(ctx) {
    let x = x -. measure_text(ctx, str) /. 2.0
    text(ctx, x, y, str, color)
  }
}

@external(javascript, "./canvas.mjs", "text")
fn text(
  ctx: Context,
  x: Float,
  y: Float,
  str: String,
  color: String,
) -> Drawable

@external(javascript, "./canvas.mjs", "measure_text")
fn measure_text(ctx: Context, str: String) -> Float

//
// ASSETS
//

@external(javascript, "./canvas.mjs", "asset_status")
fn asset_status() -> Int

@external(javascript, "./canvas.mjs", "asset_failed")
fn asset_failed() -> List(String)

pub type Image {
  Image(width: Float, height: Float)
}

/// load an image file from a url
@external(javascript, "./canvas.mjs", "image")
pub fn load_image(src: String) -> Image

pub type Audio {
  Audio(play: fn() -> Nil)
}

/// load an audio file from a url
@external(javascript, "./canvas.mjs", "audio")
pub fn load_audio(src: String) -> Audio

//
// TILEMAP
//

// maybe change this to Int?
pub opaque type TileMap {
  TileMap(src: String, image: Image, tile_width: Float, tile_height: Float)
}

/// load a tilemap image from a url
/// provide the width and height for each sprite in px
pub fn load_tilemap(src: String, tw: Float, th: Float) -> TileMap {
  let image = load_image(src)
  TileMap(src, image, tw, th)
}

/// draw a tilemap using a list of numbers which corrispond to the index of
/// each tile
///
/// this is based 1 tile index, as 0 skips drawing a tile
pub fn draw_map(map: TileMap, game_width: Float, layout: List(Float)) -> Draw {
  fn(ctx: Context) {
    let rl = map.image.width /. map.tile_width
    let drl = game_width /. map.tile_width

    layout
    |> list.index_map(fn(l, i) {
      case l {
        0.0 -> assert_drawable()
        _ -> {
          let l = l -. 1.0
          // source
          let y = l /. rl |> float.floor |> float.multiply(map.tile_width)
          let x =
            case l {
              x if x >=. rl -> float.round(l) % float.round(rl)
              x -> float.round(x)
            }
            |> int.to_float
            |> float.multiply(map.tile_width)

          // destination
          let dy =
            int.to_float(i) /. drl
            |> float.floor
            |> float.multiply(map.tile_height)
          let dx =
            case int.to_float(i) {
              x if x >=. drl -> float.round(x) % float.round(drl)
              x -> float.round(x)
            }
            |> int.to_float
            |> float.multiply(map.tile_width)

          img_pro(
            ctx,
            x,
            y,
            map.tile_width,
            map.tile_height,
            map.image,
            dx,
            dy,
            map.tile_width,
            map.tile_height,
          )
        }
      }
    })
    assert_drawable()
  }
}

@external(javascript, "./canvas.mjs", "img_pro")
fn img_pro(
  ctx: Context,
  x: Float,
  y: Float,
  w: Float,
  h: Float,
  image: Image,
  dx: Float,
  dy: Float,
  dw: Float,
  dh: Float,
) -> Drawable

@external(javascript, "./canvas.mjs", "assert_drawable")
fn assert_drawable() -> Drawable

//
// TILED
//

/// output from the 'Tiled' program .json export format
pub type Tiled {
  Tiled(
    compression_level: Int,
    height: Int,
    infinite: Bool,
    layers: List(Layer),
    next_layer_id: Int,
    next_object_id: Int,
    orientation: String,
    render_order: String,
    tiled_version: String,
    tile_height: Int,
    tile_sets: List(TileSet),
    tile_width: Int,
    type_: String,
    version: String,
    width: Int,
  )
}

pub type Layer {
  Layer(
    data: List(Int),
    height: Int,
    id: Int,
    name: String,
    opacity: Int,
    visible: Bool,
    width: Int,
    x: Int,
    y: Int,
  )
}

pub type TileSet {
  TileSet(firstgid: Int, source: String)
}

@external(javascript, "./canvas.mjs", "tiled")
fn tiled(src: String) -> dynamic.Dynamic

/// loads a Tiled .json file from a url
///
/// note: the decoder code is quite heavy at around 8KB minified
pub fn load_tiled(src: String) -> Result(Tiled, List(dynamic.DecodeError)) {
  src |> tiled |> decode_tiled
}

/// draw a tile map from a Tiled .json file
///
/// this uses the width properties in the .json file to caculate size
/// ensure your canvas size matches
pub fn draw_tiled(tilemap: TileMap, tiled: Tiled) -> Draws {
  let w = tiled.width * tiled.tile_width |> int.to_float
  tiled.layers
  |> list.filter(fn(layer) { layer.visible })
  |> list.map(fn(layer) {
    layer.data
    |> list.map(int.to_float)
    |> draw_map(tilemap, w, _)
  })
}

pub fn draw_sprite(tilemap: TileMap, id: Int, rec: Rect) -> Draw {
  fn(ctx) {
    let rl = tilemap.image.width /. tilemap.tile_width
    let l = id |> int.to_float
    // copy paste
    let y = l /. rl |> float.floor |> float.multiply(tilemap.tile_width)
    let x =
      case l {
        x if x >=. rl -> float.round(l) % float.round(rl)
        x -> float.round(x)
      }
      |> int.to_float
      |> float.multiply(tilemap.tile_width)

    img_pro(
      ctx,
      x,
      y,
      tilemap.tile_width,
      tilemap.tile_height,
      tilemap.image,
      rec.x,
      rec.y,
      rec.width,
      rec.height,
    )
  }
}

fn decode_tiled(
  data: dynamic.Dynamic,
) -> Result(Tiled, List(dynamic.DecodeError)) {
  use compressionlevel <- result.try(
    data |> dynamic.field("compressionlevel", dynamic.int),
  )
  use height <- result.try(data |> dynamic.field("height", dynamic.int))
  use infinite <- result.try(data |> dynamic.field("infinite", dynamic.bool))
  use layers <- result.try(
    data |> dynamic.field("layers", decode_layer |> dynamic.list),
  )
  use nextlayerid <- result.try(
    data |> dynamic.field("nextlayerid", dynamic.int),
  )
  use nextobjectid <- result.try(
    data |> dynamic.field("nextobjectid", dynamic.int),
  )
  use orientation <- result.try(
    data |> dynamic.field("orientation", dynamic.string),
  )
  use renderorder <- result.try(
    data |> dynamic.field("renderorder", dynamic.string),
  )
  use tiledversion <- result.try(
    data |> dynamic.field("tiledversion", dynamic.string),
  )
  use tileheight <- result.try(data |> dynamic.field("tileheight", dynamic.int))
  use tilesets <- result.try(
    data |> dynamic.field("tilesets", decode_tile_set |> dynamic.list),
  )
  use tilewidth <- result.try(data |> dynamic.field("tilewidth", dynamic.int))
  use type_ <- result.try(data |> dynamic.field("type", dynamic.string))
  use version <- result.try(data |> dynamic.field("version", dynamic.string))
  use width <- result.try(data |> dynamic.field("width", dynamic.int))
  Tiled(
    compressionlevel,
    height,
    infinite,
    layers,
    nextlayerid,
    nextobjectid,
    orientation,
    renderorder,
    tiledversion,
    tileheight,
    tilesets,
    tilewidth,
    type_,
    version,
    width,
  )
  |> Ok
}

fn decode_layer(
  data: dynamic.Dynamic,
) -> Result(Layer, List(dynamic.DecodeError)) {
  data
  |> dynamic.decode9(
    Layer,
    dynamic.field("data", dynamic.int |> dynamic.list),
    dynamic.field("height", dynamic.int),
    dynamic.field("id", dynamic.int),
    dynamic.field("name", dynamic.string),
    dynamic.field("opacity", dynamic.int),
    dynamic.field("visible", dynamic.bool),
    dynamic.field("width", dynamic.int),
    dynamic.field("x", dynamic.int),
    dynamic.field("y", dynamic.int),
  )
}

fn decode_tile_set(
  data: dynamic.Dynamic,
) -> Result(TileSet, List(dynamic.DecodeError)) {
  data
  |> dynamic.decode2(
    TileSet,
    dynamic.field("firstgid", dynamic.int),
    dynamic.field("source", dynamic.string),
  )
}
