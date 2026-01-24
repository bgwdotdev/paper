import paper
import tiled/app

pub fn main(update, view) {
  paper.Spec(
    "canvas",
    app.width,
    app.height,
    False,
    False,
    app.init,
    view,
    update,
  )
  |> paper.start
}
