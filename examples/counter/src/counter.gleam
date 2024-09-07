import gleam/int
import paper

const width = 64.0

const height = 64.0

pub fn main() {
  paper.Spec("canvas", width, height, False, False, init, view, update)
  |> paper.start
}

pub type State {
  State(count: Int)
}

fn init() -> State {
  State(0)
}

fn update(state: State, input: paper.Input) -> State {
  let state = case paper.is_pressed(input, "w") {
    True -> State(state.count + 1)
    False -> state
  }
  let state = case paper.is_pressed(input, "s") {
    True -> State(state.count - 1)
    False -> state
  }

  state
}

fn view(state: State) -> paper.Draws {
  [
    paper.draw_text_center(
      width *. 0.5,
      height *. 0.5,
      int.to_string(state.count),
      "#ffaff3",
    ),
  ]
}
