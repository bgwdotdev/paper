import paper
import tiled/app

pub fn update(state: app.State, _input: paper.Input) -> app.State {
  state
}

pub fn view(state: app.State) -> paper.Draws {
  paper.draw_tiled(state.tile_map, state.tile_layout)
}
