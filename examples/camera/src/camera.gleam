import camera/state
import gleam/io
import paper

pub fn main(
  update: fn(state.State, paper.Input) -> state.State,
  view: fn(state.State) -> List(fn(paper.Context) -> paper.Drawable),
) -> Nil {
  paper.Spec(
    "canvas",
    state.width,
    state.height,
    False,
    False,
    state.init,
    view,
    update,
  )
  |> paper.start
}
