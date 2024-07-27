import gleam/io
import gleam/set
import paper

const width = 320.0

const height = 180.0

pub fn main() {
  io.println("Hello from pong!")

  paper.Spec("canvas", width, height, False, init, view, update) |> paper.start
}

fn init() -> State {
  let background = paper.Rect(0.0, 0.0, width, height)
  let player = paper.Rect(0.0, 50.0, 20.0, 20.0)
  let enemy = paper.Rect(200.0, 50.0, 20.0, 20.0)
  let pic = paper.load_image("./teal.png")
  State(width, height, background, player, enemy, pic)
}

fn update(state: State) -> State {
  let keys = paper.get_keys()
  let paper.Rect(px, py, pw, ph) = state.player
  let paper.Rect(ex, ey, ew, eh) = state.enemy
  let collide =
    paper.collision_recs(paper.Rect(px, py, pw, ph), paper.Rect(ex, ey, ew, eh))
  // move
  let vel = case set.contains(keys, "w") {
    True -> 1.0
    False -> 0.0
  }
  let px = case px {
    x if x >. width -> 0.0
    x if collide -> x +. 0.0
    x -> x +. vel
  }
  // move2
  let vel = case set.contains(keys, "s") {
    True -> -1.0
    False -> 0.0
  }
  let px = case px {
    x if x >. width -> 0.0
    x if collide -> x +. 0.0
    x -> x +. vel
  }
  let player = paper.Rect(px, py, pw, ph)
  State(..state, player: player)
}

fn view(state: State) -> paper.Draws {
  [
    paper.draw_rec(state.background, "#292d3e"),
    paper.draw_img(state.player, state.pic),
    paper.draw_rec(state.enemy, "#ffaff3"),
  ]
}

pub type State {
  State(
    width: Float,
    height: Float,
    background: paper.Rect,
    player: paper.Rect,
    enemy: paper.Rect,
    pic: paper.Image,
  )
}
