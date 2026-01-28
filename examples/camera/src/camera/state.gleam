import gleam/int
import paper

pub const width = 320.0

pub const height = 180.0

pub const bit = 16.0

pub type State {
  State(
    count: Int,
    tilemap: paper.TileMap,
    map: paper.Tiled,
    player: paper.Rect,
  )
}

pub fn init() -> State {
  let assert Ok(map) = paper.load_tiled("map.json")
  let tilemap =
    paper.load_tilemap(
      "tilemap_packed.png",
      map.tile_height |> int.to_float,
      map.tile_width |> int.to_float,
    )
  let player = paper.Rect(0.0, 0.0, bit, bit)
  let count = 20
  State(count:, map:, tilemap:, player:)
}
