import paper

pub const width = 480.0

pub const height = 272.0

pub const speed = 2.0

pub const pi = 3.141592653589793

pub const bit = 16.0

pub type State {
  State(
    // system
    width: Float,
    height: Float,
    id: Int,
    counter: Int,
    // assets
    background: paper.Rect,
    animations: paper.TileMap,
    tiles: paper.TileMap,
    map: paper.Tiled,
    // system
    pointer: paper.Vec2,
    // unit
    tower_map: List(Float),
    towers: List(Tower),
    path: List(Float),
    // player
    health: Int,
    unit: Sprite,
    // game
    mode: Mode,
    round_start: Int,
    // enemy
    mobs: List(Mob),
    level: Int,
  )
}

pub type Mode {
  Build
  Round
  Dead
}

pub type Tower {
  Tower(
    id: Int,
    pos: paper.Vec2,
    damage: Int,
    cooldown: Int,
    attacked: Int,
    sprite: Sprite,
  )
}

pub type Mob {
  Mob(pos: paper.Vec2, health: Int, sprite: Sprite)
}

pub type Sprite {
  Bat
  Rat
  Wizard
  Knight
  Axe
  Necro
}
