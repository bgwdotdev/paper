import gleam/bool
import gleam/float
import gleam/int
import gleam/io
import gleam/pair
import paper

const width = 320.0

const height = 180.0

const speed = 2.0

pub fn main() {
  paper.Spec("canvas", width, height, False, False, init, view, update)
  |> paper.start
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
    ping: paper.Audio,
    pong: paper.Audio,
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

  let ping = paper.load_audio("ping.mp3")
  let pong = paper.load_audio("pong.mp3")

  State(
    width,
    height,
    background,
    player,
    enemy,
    ball,
    float.negate(speed),
    score,
    ping,
    pong,
  )
}

fn update(state: State, input: paper.Input) -> State {
  // player movement
  let v = 0.0
  let v =
    paper.is_down(input, "w")
    |> bool.and(state.player.y >. 0.0)
    |> paper.guard(float.negate(speed), v)
  let v =
    paper.is_down(input, "s")
    |> bool.and({ state.player.y +. state.player.height } <. height)
    |> paper.guard(speed, v)

  // ball movement
  let ball = paper.Rect(..state.ball, x: state.ball.x +. state.ball_vel)
  let ball_vel = state.ball_vel
  let ball_vel =
    paper.collision_recs(state.player, ball)
    |> bool.negate
    |> bool.guard(ball_vel, fn() {
      state.pong.play()
      speed
    })
  let ball_vel =
    paper.collision_recs(state.enemy, ball)
    |> bool.negate
    |> bool.guard(ball_vel, fn() {
      state.ping.play()
      float.negate(speed)
    })
  let ball = paper.Rect(..state.ball, x: state.ball.x +. state.ball_vel)

  // score
  let ledge = 0.0
  let redge = width -. state.ball.width
  let #(score, ball, ball_vel) = case state.ball.x {
    x if x <. ledge -> {
      let score = state.score |> pair.map_second(fn(s) { s + 1 })
      let ball =
        paper.Rect(..state.ball, x: { width -. state.ball.width } /. 2.0)
      let ball_vel = ball_vel /. 3.0
      #(score, ball, ball_vel)
    }
    x if x >. redge -> {
      let score = state.score |> pair.map_first(fn(s) { s + 1 })
      let ball =
        paper.Rect(..state.ball, x: { width -. state.ball.width } /. 2.0)
      let ball_vel = ball_vel /. 3.0
      #(score, ball, ball_vel)
    }
    _ -> #(state.score, ball, ball_vel)
  }

  let player = paper.Rect(..state.player, y: state.player.y +. v)
  State(..state, player: player, ball: ball, ball_vel: ball_vel, score: score)
}

fn view(state: State) -> paper.Draws {
  let #(p, e) = state.score
  [
    paper.draw_rec(state.background, "#292d3e"),
    paper.draw_text_center(width *. 0.25, 10.0, int.to_string(p), "#ffaff3"),
    paper.draw_text_center(width *. 0.75, 10.0, int.to_string(e), "#ffaff3"),
    paper.draw_rec(state.player, "#ffaff3"),
    paper.draw_rec(state.enemy, "#ffaff3"),
    paper.draw_rec(state.ball, "#ffaff3"),
  ]
}
