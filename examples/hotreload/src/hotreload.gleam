import hotreload/app
import paper

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
