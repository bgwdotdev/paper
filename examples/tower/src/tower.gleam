import gleam/int
import gleam/list
import gleam/result
import paper
import tower/state.{type State, State}

pub fn main(update, view) {
  paper.Spec(
    "canvas",
    state.width,
    state.height,
    False,
    False,
    init,
    view,
    update,
  )
  |> paper.start
}

fn init() -> State {
  let background = paper.Rect(0.0, 0.0, state.width, state.height)
  let assert Ok(map) = paper.load_tiled("public/tower.json")
  let tiles =
    paper.load_tilemap(
      "public/tilemap_packed.png",
      map.tile_height |> int.to_float,
      map.tile_width |> int.to_float,
    )
  let animations = paper.load_tilemap("public/animation.png", 16.0, 16.0)

  let assert Ok(path) =
    map.layers
    |> list.filter(fn(l) { l.name == "path" })
    |> list.first
    |> result.map(fn(l) { l.data |> list.map(int.to_float) })
  let assert Ok(tower_map) =
    map.layers |> list.filter(fn(l) { l.name == "tower" }) |> list.first
  let tower_map =
    list.map(tower_map.data, fn(x) {
      case x {
        61 -> 1.0
        _ -> 0.0
      }
    })

  State(
    width: state.width,
    height: state.height,
    id: 0,
    counter: 0,
    background:,
    animations:,
    tiles:,
    map:,
    pointer: paper.Vec2(0.0, 0.0),
    tower_map:,
    towers: [],
    path:,
    health: 10,
    unit: state.Knight,
    mode: state.Build,
    round_start: 0,
    mobs: [],
    level: 1,
  )
}
