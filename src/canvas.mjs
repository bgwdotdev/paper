import * as $set from "../gleam_stdlib/gleam/set.mjs";

//
// CORE
//

export function init_canvas(id, w, h) {
  const canvas = document.getElementById(id);
  const ctx = canvas.getContext("2d");
  canvas.width = w
  canvas.height = h
  return [canvas, ctx]
}

export function clear_canvas(ctx) {
  ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height)
}

export function draw_canvas(draw) {
  requestAnimationFrame(draw);
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

export function text(ctx, x, y, text) {
  ctx.fillText(text, x, y);
}
