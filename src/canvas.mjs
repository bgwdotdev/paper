import * as $set from "../gleam_stdlib/gleam/set.mjs";
import * as $dict from "../gleam_stdlib/gleam/dict.mjs";
import * as $list from "../gleam_stdlib/gleam/list.mjs";

//
// CORE
//

export function window_size() {
  return [window.innerWidth, window.innerHeight]
}

export function window_resize(fn) {
  window.addEventListener('resize', fn, 250);
}

export function init_canvas(id, w, h, s, smooth) {
  const canvas = document.getElementById(id);
  const ctx = canvas.getContext("2d");
  canvas.width = w * s
  canvas.height = h * s
  ctx.imageSmoothingEnabled = smooth;
  return [canvas, ctx]
}

export function create_canvas(w, h) {
  const canvas = document.createElement("canvas");
  const ctx = canvas.getContext("2d");
  canvas.width = w;
  canvas.height = h;
  return ctx
}

export function clear_canvas(ctx) {
  ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height)
}

export function draw_canvas(draw) {
  requestAnimationFrame(draw);
}

export function resize_canvas(ctx, w, h) {
  ctx.canvas.width = w;
  ctx.canvas.height = h;
}

export function scale_canvas(ctx, x, y) {
  ctx.scale(x, y);
}

export function now() {
  return performance.now()
}

//
// INPUT
//

// KEYBOARD

let keys = $set.new$();

export function init_keydown(fn, thinga) {
  window.addEventListener('keydown', function(e) {
    keys = fn(e, keys);
  });

  // clear inputs on loss of focus
  window.addEventListener('blur', function() {
    keys = $set.new$();
  });
}

export function init_keyup(fn, thinga) {
  window.addEventListener('keyup', function(e) {
    keys = fn(e, keys);
  });
}

export function get_keys() {
  return keys
}

// MOUSE

let mouse = $dict.new$();

export function init_mousemove(fn, scale) {
  canvas.addEventListener('mousemove', (e) => {
    mouse = fn(e, mouse);
  });
}

export function init_mousedown(fn, scale) {
  canvas.addEventListener('mousedown', (e) => {
    mouse = fn(e, mouse);
  });
}

export function init_mouseup(fn, scale) {
  canvas.addEventListener('mouseup', (e) => {
    mouse = fn(e, mouse);
  });
}

// canvas position relative to the window
export function get_offset(e) {
  return { x: e.target.offsetLeft, y: e.target.offsetTop }
}

export function get_mouse() {
  return mouse;
}

//
// DRAW METHODS
//

export function rec(ctx, x, y, w, h, c) {
  ctx.fillStyle = c;
  ctx.fillRect(x, y, w, h);
}

export function img(ctx, x, y, w, h, image) {
  ctx.drawImage(image, x, y, w, h);
}

export function text(ctx, x, y, text, color) {
  ctx.fillStyle = color;
  ctx.fillText(text, x, y);
}

export function measure_text(ctx, text) {
  return ctx.measureText(text).width;
}

//
// ASSETS
//

let loading = 0;
let failed = $list.new$();

export function asset_status() {
  return loading;
}

export function asset_failed() {
  return failed;
}

export function image(src) {
  loading++;
  const img = new Image();
  img.onload = () => { loading--; };
  img.onerror = () => {
    failed = $list.prepend(failed, src);
    loading = -1;
  };
  img.src = src;
  return img
}

export function audio(src) {
  loading++;
  const aud = new Audio();
  aud.addEventListener("canplaythrough", () => { loading--; });
  aud.addEventListener("error", () => {
    failed = $list.prepend(failed, src);
    loading = -1;
  });
  aud.src = src;
  return aud
}


//
// TILEMAP
//

export function img_pro(ctx, x, y, w, h, image, dx, dy, dw, dh) {
  ctx.drawImage(image, x, y, w, h, dx, dy, dw, dh);
}

export function assert_drawable() {}


//
// TILED
//

// TODO; async-ify this?
// TODO: hot-reload maybe as well?
export function tiled(src) {
  loading++;
  var req = new XMLHttpRequest();
  req.open("GET", src, false);
  req.send(null);
  if (req.status === 200) {
    loading--;
    return JSON.parse(req.responseText);
  } else {
    loading = -1;
  };
}
