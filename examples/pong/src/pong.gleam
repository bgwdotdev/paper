//// move2

import gleam/bool
import gleam/float
import gleam/io
import paper

const width = 320.0

const height = 180.0

const speed = 2.0

pub fn main() {
  paper.Spec("canvas", width, height, False, init, view, update) |> paper.start
}

pub type State {
  State(
    width: Float,
    height: Float,
    background: paper.Rect,
    player: paper.Rect,
    enemy: paper.Rect,
    ball: paper.Rect,
    ball_vel: Float,
    score: #(Int, Int),
  )
}

fn init() -> State {
  let paddle_width = 2.5
  let paddle_height = 40.0
  let background = paper.Rect(0.0, 0.0, width, height)

  let player = paper.Rect(5.0, 20.0, paddle_width, paddle_height)
  let enemy =
    paper.Rect(width -. paddle_width -. 5.0, 70.0, paddle_width, paddle_height)
  let ball = paper.Rect(width /. 2.0, height /. 2.0, 2.0, 2.0)
  let score = #(0, 0)

  State(
    width,
    height,
    background,
    player,
    enemy,
    ball,
    float.negate(speed),
    score,
  )
}

fn update(state: State) -> State {
  let keys = paper.get_keys()

  // player movement
  let v = 0.0
  let v =
    paper.is_down(keys, "w")
    |> bool.and(state.player.y >. 0.0)
    |> bool.guard(float.negate(speed), fn() { v })
  let v =
    paper.is_down(keys, "s")
    |> bool.and({ state.player.y +. state.player.height } <. height)
    |> bool.guard(speed, fn() { v })

  // ball movement
  let ball = paper.Rect(..state.ball, x: state.ball.x +. state.ball_vel)
  let ball_vel = state.ball_vel
  let ball_vel =
    paper.collision_recs(state.player, ball)
    |> bool.guard(float.negate(ball_vel), fn() { ball_vel })
  let ball_vel =
    paper.collision_recs(state.enemy, ball)
    |> bool.guard(float.negate(ball_vel), fn() { ball_vel })

  let player = paper.Rect(..state.player, y: state.player.y +. v)
  let ball = paper.Rect(..state.ball, x: state.ball.x +. state.ball_vel)
  State(..state, player: player, ball: ball, ball_vel: ball_vel)
}

fn view(state: State) -> paper.Draws {
  [
    paper.draw_rec(state.background, "#292d3e"),
    paper.draw_rec(state.player, "#ffaff3"),
    paper.draw_rec(state.enemy, "#ffaff3"),
    paper.draw_rec(state.ball, "#ffaff3"),
  ]
}
