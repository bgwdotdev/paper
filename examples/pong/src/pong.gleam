import gleam/io
import gleam/set
import paper

const width = 300

const wf = 300.0

const height = 300

pub fn main() {
  io.println("Hello from pong!")

  paper.Spec("canvas", width, height, init, view, update) |> paper.start
}

fn init() -> State {
  let player = paper.Rect(0.0, 50.0, 20.0, 20.0, "blue")
  let enemy = paper.Rect(200.0, 50.0, 20.0, 20.0, "red")
  State(width, height, player, enemy)
}

fn update(state: State) -> State {
  let keys = paper.get_keys()
  let paper.Rect(px, py, pw, ph, pc) = state.player
  let paper.Rect(ex, ey, ew, eh, ec) = state.enemy
  let collide =
    paper.collision_recs(
      paper.Rect(px, py, pw, ph, pc),
      paper.Rect(ex, ey, ew, eh, ec),
    )
  // move
  let vel = case set.contains(keys, "w") {
    True -> 1.0
    False -> 0.0
  }
  let px = case px {
    x if x >. wf -> 0.0
    x if collide -> x +. 0.0
    x -> x +. vel
  }
  // move2
  let vel = case set.contains(keys, "s") {
    True -> -1.0
    False -> 0.0
  }
  let px = case px {
    x if x >. wf -> 0.0
    x if collide -> x +. 0.0
    x -> x +. vel
  }
  let player = paper.Rect(px, py, pw, ph, pc)
  State(..state, player: player)
}

fn view(state: State) -> paper.Draws {
  [paper.draw_rec(state.player), paper.draw_rec(state.enemy)]
}

pub type State {
  State(width: Int, height: Int, player: paper.Rect, enemy: paper.Rect)
}
