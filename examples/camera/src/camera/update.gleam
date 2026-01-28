import camera/state.{type State}
import gleam/bool
import gleam/float
import gleam/list
import paper

pub fn update(state: State, input: paper.Input) -> State {
  let state =
    bool.guard(!paper.is_down(input, "w"), state, fn() {
      state.State(
        ..state,
        player: paper.Rect(..state.player, y: state.player.y -. 1.0),
      )
    })
  let state =
    bool.guard(!paper.is_down(input, "s"), state, fn() {
      state.State(
        ..state,
        player: paper.Rect(..state.player, y: state.player.y +. 1.0),
      )
    })
  let state =
    bool.guard(!paper.is_down(input, "a"), state, fn() {
      state.State(
        ..state,
        player: paper.Rect(..state.player, x: state.player.x -. 1.0),
      )
    })
  let state =
    bool.guard(!paper.is_down(input, "d"), state, fn() {
      state.State(
        ..state,
        player: paper.Rect(..state.player, x: state.player.x +. 1.0),
      )
    })
  state
}

pub fn view(state: State) -> paper.Draws {
  let zoom = 1.5
  [
    paper.draw_tiled(state.tilemap, state.map),
    [paper.draw_sprite(state.tilemap, 109, state.player)],
  ]
  |> list.flatten
  |> paper.camera_follow(state.width, state.height, zoom, state.player, _)
}
