import gleam/int
import paper

pub const width = 48.0

pub const height = 48.0

pub const bit = 16.0

pub type State {
  State(tile_layout: paper.Tiled, tile_map: paper.TileMap)
}

pub fn init() -> State {
  let assert Ok(tile_layout) = paper.load_tiled("public/tiled.json")
  let tile_map =
    paper.load_tilemap(
      "public/tilemap_packed.png",
      tile_layout.tile_height |> int.to_float,
      tile_layout.tile_width |> int.to_float,
    )
  State(tile_layout:, tile_map:)
}
