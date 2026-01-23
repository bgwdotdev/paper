import gleam/int
import paper

pub const width = 64.0

pub const height = 64.0

pub type State {
  State(count: Int)
}

pub fn init() -> State {
  State(0)
}

pub fn view(state: State) -> paper.Draws {
  [
    paper.draw_text_center(
      width *. 0.5,
      height *. 0.5,
      int.to_string(state.count),
      "#ffaff3",
    ),
  ]
}
