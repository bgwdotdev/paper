import * as $set from "../gleam_stdlib/gleam/set.mjs";

//
// CORE
//

export function window_size() {
  return [window.innerWidth, window.innerHeight]
}

export function window_resize(fn) {
  window.addEventListener('resize', fn, 250);
}

export function init_canvas(id, w, h, s) {
  const canvas = document.getElementById(id);
  const ctx = canvas.getContext("2d");
  canvas.width = w * s
  canvas.height = h * s
  return [canvas, ctx]
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

export function text(ctx, x, y, text) {
  ctx.fillText(text, x, y);
}

export function measure_text(ctx, text) {
  return ctx.measureText(text);
}

//
// ASSETS
//

export function image(src) {
  const img = new Image();
  img.src = src;
  return img
}

export function audio(src) {
  const aud = new Audio();
  aud.src = src;
  return aud
}
