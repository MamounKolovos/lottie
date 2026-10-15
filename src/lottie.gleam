import glam/doc
import gleam/bool
import gleam/deque.{type Deque}
import gleam/dict.{type Dict}
import gleam/dynamic/decode.{type Decoder}
import gleam/float
import gleam/int
import gleam/io
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import iv
import lottie/internal/affine.{type Affine}
import lottie/internal/math
import lottie/internal/runtime
import lustre
import lustre/attribute.{type Attribute}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/svg
import rsvp

// import simplifile

pub fn main() -> Nil {
  // let assert Ok(raw) = simplifile.read("./priv/Basic_Comp.json")
  // case json.parse(raw, animation_decoder()) {
  //   Ok(animation) -> {
  //     echo animation
  //     io.println("")
  //     element.to_readable_string(compile(animation, 0.0)) |> io.println
  //     Nil
  //   }
  //   Error(e) -> {
  //     echo e
  //     Nil
  //   }
  // }

  // let assert Ok(square) = json.parse(square_path_string, bezier_path_decoder())
  // echo square
  // echo bezier_path_to_attribute(square)
  // let animation = json.parse(raw, animation_decoder())

  // echo animation

  // echo compile(animation)
  // Nil
  let app = lustre.application(init:, update:, view:)
  let assert Ok(_) = lustre.start(app, onto: "#app", with: Nil)
  Nil
}

pub type Model {
  Loading
  Loaded(animation: Animation, playback: Playback, current_frame: Float)
}

pub type Playback {
  Playback(state: PlaybackState, mode: PlaybackMode)
}

pub type PlaybackState {
  Playing
  Paused
}

pub type PlaybackMode {
  Loop
  Once(done: Bool)
}

pub type Message {
  ReturnedAnimation(Result(Animation, rsvp.Error(String)))
  Ticked(dt: Float)
}

pub fn init(_args: Nil) -> #(Model, Effect(Message)) {
  let fetch_animation =
    rsvp.get(
      // "/Basic_Comp.json",
      "/Lottiefiles_Basic_Comp.json",
      // "/trophy.json",
      rsvp.expect_json(animation_decoder(), ReturnedAnimation),
    )
  #(Loading, fetch_animation)
}

pub fn update(model: Model, message: Message) -> #(Model, Effect(Message)) {
  case model, message {
    Loading, ReturnedAnimation(animation) ->
      case animation {
        Ok(animation) -> #(
          Loaded(
            animation:,
            playback: Playback(state: Playing, mode: Loop),
            current_frame: animation.in_point,
          ),
          runtime.start(Ticked),
        )
        Error(e) -> {
          echo e
          #(model, effect.none())
        }
      }
    Loaded(animation:, playback:, current_frame:), Ticked(dt:) -> {
      case playback {
        Playback(state: Paused, ..) -> #(model, effect.none())
        Playback(mode: Once(done: True), ..) -> #(model, effect.none())
        Playback(state: Playing, mode: Once(done: False)) -> {
          let next_frame = current_frame +. { dt *. animation.fps }
          case next_frame >=. animation.out_point {
            True -> {
              let playback = Playback(..playback, mode: Once(done: True))
              let model =
                Loaded(..model, playback:, current_frame: animation.out_point)
              #(model, effect.none())
            }
            False -> {
              let model = Loaded(..model, current_frame: next_frame)
              #(model, effect.none())
            }
          }
        }
        Playback(state: Playing, mode: Loop) -> {
          let next_frame = current_frame +. { dt *. animation.fps }
          case next_frame >=. animation.out_point {
            True -> {
              let next_frame =
                animation.in_point +. { next_frame -. animation.out_point }
              let model = Loaded(..model, current_frame: next_frame)
              #(model, effect.none())
            }
            False -> {
              let model = Loaded(..model, current_frame: next_frame)
              #(model, effect.none())
            }
          }
        }
      }
    }
    model, _ -> #(model, effect.none())
  }
}

//also need to look into caching static subtrees, not really sure how that would work
pub fn view(model: Model) -> Element(Message) {
  case model {
    Loading -> element.none()
    Loaded(animation:, current_frame:, ..) -> {
      compile(animation, current_frame)
    }
  }
}

pub fn compile(animation: Animation, frame: Float) -> Element(Message) {
  html.svg(
    [attribute.width(animation.width), attribute.height(animation.height)],
    // the first element in lottie has the highest z-index
    // the last element in svg has the highest z index
    list.reverse(animation.layers)
      |> list.map(fn(layer) {
        compile_layer(layer, animation.index_to_layer, frame)
      }),
  )
}

pub type Animation {
  Animation(
    fps: Float,
    in_point: Float,
    out_point: Float,
    width: Int,
    height: Int,
    layers: List(Layer),
    index_to_layer: Dict(Int, Layer),
  )
}

pub fn animation_decoder() -> Decoder(Animation) {
  use fps <- decode.field("fr", decode.float)
  use in_point <- decode.field("ip", decode.float)
  use out_point <- decode.field("op", decode.float)
  use width <- decode.field("w", decode.int)
  use height <- decode.field("h", decode.int)
  use #(layers, index_to_layer) <- decode.field("layers", {
    use index_layer_pairs <- decode.then(decode.list(of: layer_decoder()))

    let layers = list.map(index_layer_pairs, fn(pair) { pair.1 })
    let index_to_layer =
      list.fold(index_layer_pairs, from: dict.new(), with: fn(acc, pair) {
        let #(index, layer) = pair
        case index {
          option.Some(index) -> dict.insert(acc, index, layer)
          option.None -> acc
        }
      })
    decode.success(#(layers, index_to_layer))
  })
  decode.success(Animation(
    fps:,
    in_point:,
    out_point:,
    width:,
    height:,
    layers:,
    index_to_layer:,
  ))
}

//TODO: add name field and determine if it belongs here or inside the variant types
pub type Layer {
  VisualLayer(VisualLayer)
  DataLayer
}

pub type VisualLayer {
  NullLayer(
    hidden: Bool,
    parent_index: Option(Int),
    time_stretch: Float,
    in_point: Int,
    out_point: Int,
    start_time: Int,
    transform: Transform,
  )
  ShapeLayer(
    hidden: Bool,
    parent_index: Option(Int),
    time_stretch: Float,
    in_point: Int,
    out_point: Int,
    start_time: Int,
    transform: Transform,
    elements: List(GraphicElement),
  )
}

fn compile_layer(
  layer: Layer,
  index_to_layer: Dict(Int, Layer),
  frame: Float,
) -> Element(Message) {
  case layer {
    VisualLayer(layer) -> {
      //TODO: resultify this shouldnt be using options for this kind of thing
      let parent_transform = {
        use parent_index <- option.then(layer.parent_index)
        use parent_layer <- option.then(
          dict.get(index_to_layer, parent_index) |> option.from_result,
        )
        case parent_layer {
          VisualLayer(parent_layer) -> option.Some(parent_layer.transform)
          DataLayer -> option.None
        }
      }

      //TODO: determine if im going to mandate that every layer have a parent
      // because im pretty sure most lottie exporters force a top level parent that all layers inherit from
      case parent_transform {
        option.Some(parent_transform) ->
          compile_visual_layer(layer, parent_transform, frame)
        option.None -> compile_visual_layer(layer, identity_transform, frame)
      }
    }
    DataLayer -> element.none()
  }
}

fn compile_visual_layer(
  layer: VisualLayer,
  parent_transform: Transform,
  frame: Float,
) -> Element(Message) {
  let #(parent_affine, _) = from_transform(parent_transform, frame)
  let #(child_affine, opacity) = from_transform(layer.transform, frame)
  let final_affine = affine.multiply(parent_affine, child_affine)

  svg.g(
    [
      affine.to_attribute(final_affine),
      attribute.attribute("opacity", float.to_string(opacity)),
    ],
    [
      case layer {
        NullLayer(..) -> element.none()
        ShapeLayer(
          hidden:,
          parent_index:,
          time_stretch:,
          in_point:,
          out_point:,
          start_time:,
          transform:,
          elements:,
        ) -> list.reverse(elements) |> compile_graphic_elements_loop([], frame)
      },
    ],
  )
}

fn compile_graphic_elements_loop(
  elements: List(GraphicElement),
  styles: List(Style),
  frame: Float,
) -> Element(Message) {
  let #(nodes, _) =
    list.fold(elements, from: #([], styles), with: fn(acc, element) {
      let #(nodes, styles) = acc

      case element {
        Shape(shape) -> {
          let node = compile_shape(shape, styles, frame)
          #([node, ..nodes], styles)
        }
        Style(style) -> #(nodes, [style, ..styles])
        Group(name:, hidden: False, elements:) -> {
          let node = list.reverse(elements) |> compile_group_loop(styles, frame)
          #([node, ..nodes], styles)
        }
        Group(hidden: True, ..) -> acc
        TransformElement(transform:) -> acc
        UnknownElement(name:, type_:) -> acc
      }
    })

  element.fragment(nodes)
}

fn compile_group_loop(
  elements: List(GraphicElement),
  styles: List(Style),
  frame: Float,
) -> Element(Message) {
  case elements {
    [TransformElement(transform:), ..elements] -> {
      let children = compile_graphic_elements_loop(elements, styles, frame)
      let #(affine, opacity) = from_transform(transform, frame)
      svg.g(
        [
          affine.to_attribute(affine),
          attribute.attribute("opacity", float.to_string(opacity)),
        ],
        [children],
      )
    }
    _ -> element.none()
  }
}

pub fn layer_decoder() -> Decoder(#(Option(Int), Layer)) {
  use ddd <- decode.field("ddd", integer_boolean_decoder())
  use <- bool.guard(
    ddd,
    return: decode.failure(#(option.None, DataLayer), expected: "2D layer"),
  )

  use hidden <- decode.optional_field("hd", False, decode.bool)
  use parent_index <- field_option("parent", decode.int)
  use time_stretch <- decode.optional_field("sr", 1.0, decode.float)
  use in_point <- decode.field("ip", decode.int)
  use out_point <- decode.field("op", decode.int)
  use start_time <- decode.field("st", decode.int)

  use index <- field_option("ind", decode.int)

  use type_ <- decode.field("ty", decode.int)
  case type_ {
    3 -> {
      use transform <- decode.field("ks", transform_decoder())
      decode.success(#(
        index,
        NullLayer(
          hidden:,
          parent_index:,
          time_stretch:,
          in_point:,
          out_point:,
          start_time:,
          transform:,
        )
          |> VisualLayer,
      ))
    }
    4 -> {
      use transform <- decode.field("ks", transform_decoder())
      use elements <- decode.field(
        "shapes",
        decode.list(of: graphic_element_decoder()),
      )
      decode.success(#(
        index,
        ShapeLayer(
          hidden:,
          parent_index:,
          time_stretch:,
          in_point:,
          out_point:,
          start_time:,
          transform:,
          elements:,
        )
          |> VisualLayer,
      ))
    }
    _ -> decode.failure(#(option.None, DataLayer), expected: "Layer")
  }
}

pub type BaseLayer {
  BaseLayer(
    hidden: Bool,
    index: Int,
    parent_index: Option(Int),
    time_stretch: Float,
    in_point: Int,
    out_point: Int,
    start_time: Int,
  )
}

pub fn base_layer_decoder() -> Decoder(BaseLayer) {
  use ddd <- decode.field("ddd", integer_boolean_decoder())
  use <- bool.guard(
    ddd,
    return: decode.failure(
      BaseLayer(
        hidden: False,
        index: 0,
        parent_index: option.None,
        time_stretch: 0.0,
        in_point: 0,
        out_point: 0,
        start_time: 0,
      ),
      "2D layer",
    ),
  )

  use hidden <- decode.optional_field("hd", False, decode.bool)
  use index <- decode.field("ind", decode.int)
  use parent_index <- field_option("parent", decode.int)
  use time_stretch <- decode.optional_field("sr", 1.0, decode.float)
  use in_point <- decode.field("ip", decode.int)
  use out_point <- decode.field("op", decode.int)
  use start_time <- decode.field("st", decode.int)
  decode.success(BaseLayer(
    hidden:,
    index:,
    parent_index:,
    time_stretch:,
    in_point:,
    out_point:,
    start_time:,
  ))
}

// i imagine if you have something like [rect, circle, fill, ellipse, stroke, transform] the compilation would look like
// 1. i see stroke so so i add it to my style queue
// 2. i see ellipse so i apply stroke to it
// 3. i see fill so i add it to the back of my style queue
// 4. i see circle so i iterate my style queue and apply stroke then fill
// 5. i see rect so i iterate my style queue and apply stroke then fill
pub type GraphicElement {
  Shape(Shape)
  Style(Style)
  TransformElement(transform: Transform)
  Group(name: Option(String), hidden: Bool, elements: List(GraphicElement))
  UnknownElement(name: Option(String), type_: String)
}

//TODO: add gradient fill
pub type Style {
  Stroke(
    name: Option(String),
    hidden: Bool,
    opacity: Property(Float, Float),
    width: Property(Float, Float),
    color: Property(Color, Float),
  )
  Fill(
    name: Option(String),
    hidden: Bool,
    fill_rule: FillRule,
    opacity: Property(Float, Float),
    color: Property(Color, Float),
  )
}

pub type FillRule {
  NonZero
  EvenOdd
}

fn fill_rule_attribute(fill_rule: FillRule) -> Attribute(Message) {
  attribute.attribute("fill-rule", case fill_rule {
    NonZero -> "nonzero"
    EvenOdd -> "evenodd"
  })
}

fn fill_rule_decoder() -> Decoder(FillRule) {
  use value <- decode.then(decode.int)
  case value {
    1 -> decode.success(NonZero)
    2 -> decode.success(EvenOdd)
    _ -> decode.failure(NonZero, "FillRule")
  }
}

pub type Shape {
  Rectangle(
    name: Option(String),
    hidden: Bool,
    direction: ShapeDirection,
    position: Position,
    size: Property(Vector, Vector),
    corner_radius: Property(Float, Float),
  )
  Ellipse(
    name: Option(String),
    hidden: Bool,
    direction: ShapeDirection,
    position: Position,
    size: Property(Vector, Vector),
  )
  Polystar(
    name: Option(String),
    hidden: Bool,
    direction: ShapeDirection,
    position: Position,
    rotation: Property(Float, Float),
    //TODO: prob make this an int alongside an `int_scalar_property_decoder`
    point_count: Property(Float, Float),
    outer_radius: Property(Float, Float),
    outer_roundness: Property(Float, Float),
    inner_radius: Property(Float, Float),
    inner_roundness: Property(Float, Float),
  )
  RegularPolygon(
    name: Option(String),
    hidden: Bool,
    direction: ShapeDirection,
    position: Position,
    rotation: Property(Float, Float),
    point_count: Property(Float, Float),
    radius: Property(Float, Float),
    roundness: Property(Float, Float),
  )
  Path(
    name: Option(String),
    hidden: Bool,
    direction: ShapeDirection,
    path: Property(Path, Float),
  )
}

pub type ShapeDirection {
  /// Clockwise
  Normal
  /// Counterclockwise
  Reversed
}

fn shape_direction_decoder() -> Decoder(ShapeDirection) {
  use value <- decode.then(decode.int)
  case value {
    1 -> decode.success(Normal)
    3 -> decode.success(Reversed)
    _ -> decode.failure(Normal, "ShapeDirection")
  }
}

// control point handle length as a fraction of the radius for approximating a quarter-circle arc
const k = 0.5522847498

fn compile_shape(
  shape: Shape,
  styles: List(Style),
  frame: Float,
) -> Element(Message) {
  use <- bool.guard(shape.hidden, return: element.none())

  let path = case shape {
    Rectangle(name:, hidden:, direction:, position:, size:, corner_radius:) -> {
      let position = position_at_frame(position, frame)
      let size = value_at_frame(size, frame, vector_interpolator())
      let corner_radius =
        value_at_frame(corner_radius, frame, scalar_interpolator())

      let x_radius = size.x /. 2.0
      let y_radius = size.y /. 2.0

      let left = position.x -. x_radius
      let top = position.y -. y_radius
      let right = position.x +. x_radius
      let bottom = position.y +. y_radius

      let corner_radius =
        float.min(corner_radius, float.min(x_radius, y_radius))
      let kr = k *. corner_radius

      let top_left_start =
        Vertex(
          position: Vector(left, top +. corner_radius),
          out_tangent: Vector(0.0, -1.0 *. kr),
          in_tangent: Vector(0.0, 0.0),
        )

      let top_left_end =
        Vertex(
          position: Vector(left +. corner_radius, top),
          out_tangent: Vector(0.0, 0.0),
          in_tangent: Vector(-1.0 *. kr, 0.0),
        )

      let top_right_start =
        Vertex(
          position: Vector(right -. corner_radius, top),
          out_tangent: Vector(kr, 0.0),
          in_tangent: Vector(0.0, 0.0),
        )

      let top_right_end =
        Vertex(
          position: Vector(right, top +. corner_radius),
          out_tangent: Vector(0.0, 0.0),
          in_tangent: Vector(0.0, -1.0 *. kr),
        )

      let bottom_right_start =
        Vertex(
          position: Vector(right, bottom -. corner_radius),
          out_tangent: Vector(0.0, kr),
          in_tangent: Vector(0.0, 0.0),
        )

      let bottom_right_end =
        Vertex(
          position: Vector(right -. corner_radius, bottom),
          out_tangent: Vector(0.0, 0.0),
          in_tangent: Vector(kr, 0.0),
        )

      let bottom_left_start =
        Vertex(
          position: Vector(left +. corner_radius, bottom),
          out_tangent: Vector(-1.0 *. kr, 0.0),
          in_tangent: Vector(0.0, 0.0),
        )

      let bottom_left_end =
        Vertex(
          position: Vector(left, bottom -. corner_radius),
          out_tangent: Vector(0.0, 0.0),
          in_tangent: Vector(0.0, kr),
        )

      ClosedPath(
        first: top_left_start,
        second: top_left_end,
        third: top_right_start,
        rest: [
          top_right_end,
          bottom_right_start,
          bottom_right_end,
          bottom_left_start,
          bottom_left_end,
        ],
      )
    }
    Ellipse(name:, hidden:, direction:, position:, size:) -> {
      let position = position_at_frame(position, frame)
      let size = value_at_frame(size, frame, vector_interpolator())

      let x_radius = size.x /. 2.0
      let y_radius = size.y /. 2.0

      let left =
        Vertex(
          position: Vector(position.x -. x_radius, position.y),
          out_tangent: Vector(0.0, -1.0 *. k *. y_radius),
          in_tangent: Vector(0.0, k *. y_radius),
        )

      let top =
        Vertex(
          position: Vector(position.x, position.y -. y_radius),
          out_tangent: Vector(k *. x_radius, 0.0),
          in_tangent: Vector(-1.0 *. k *. x_radius, 0.0),
        )

      let right =
        Vertex(
          position: Vector(position.x +. x_radius, position.y),
          out_tangent: Vector(0.0, k *. y_radius),
          in_tangent: Vector(0.0, -1.0 *. k *. y_radius),
        )

      let bottom =
        Vertex(
          position: Vector(position.x, position.y +. y_radius),
          out_tangent: Vector(-1.0 *. k *. x_radius, 0.0),
          in_tangent: Vector(k *. x_radius, 0.0),
        )

      ClosedPath(first: left, second: top, third: right, rest: [bottom])
    }
    Polystar(
      name:,
      hidden:,
      direction:,
      position:,
      rotation:,
      point_count:,
      outer_radius:,
      outer_roundness:,
      inner_radius:,
      inner_roundness:,
    ) -> {
      let position = position_at_frame(position, frame)
      let rotation = rotation_at_frame(rotation, frame)
      let point_count =
        value_at_frame(point_count, frame, scalar_interpolator())
        |> float.truncate
      let outer_radius =
        value_at_frame(outer_radius, frame, scalar_interpolator())
      let outer_roundness =
        value_at_frame(outer_roundness, frame, scalar_interpolator()) /. 100.0
      let inner_radius =
        value_at_frame(inner_radius, frame, scalar_interpolator())
      let inner_roundness =
        value_at_frame(inner_roundness, frame, scalar_interpolator()) /. 100.0

      let angle_step = { 2.0 *. math.pi() } /. int.to_float(point_count)

      let outer_tangent_length =
        polygon_roundness_tangent_length(
          radius: outer_radius,
          roundness: outer_roundness,
          point_count:,
        )

      let inner_tangent_length =
        polygon_roundness_tangent_length(
          radius: inner_radius,
          roundness: inner_roundness,
          point_count:,
        )

      let vertices =
        int.range(from: 0, to: point_count, with: [], run: fn(vertices, i) {
          let outer_angle =
            { int.to_float(i) *. angle_step }
            -. { math.pi() /. 2.0 }
            +. rotation

          let outer_vertex =
            vertex_on_circle(
              center: position,
              radius: outer_radius,
              angle: outer_angle,
              tangent_length: outer_tangent_length,
            )

          // half step phase shift, one of the key geometric properties of a star
          let inner_angle = outer_angle +. { angle_step /. 2.0 }
          let inner_vertex =
            vertex_on_circle(
              center: position,
              radius: inner_radius,
              angle: inner_angle,
              tangent_length: inner_tangent_length,
            )

          [inner_vertex, outer_vertex, ..vertices]
        })
        |> list.reverse

      //TODO: replace assert with early return
      let assert [first, second, third, ..rest] = vertices
      ClosedPath(first:, second:, third:, rest:)
    }
    RegularPolygon(
      name:,
      hidden:,
      direction:,
      position:,
      rotation:,
      point_count:,
      radius:,
      roundness:,
    ) -> {
      let position = position_at_frame(position, frame)
      let rotation = rotation_at_frame(rotation, frame)
      let radius = value_at_frame(radius, frame, scalar_interpolator())
      let roundness = roundness_at_frame(roundness, frame)
      //TODO: figure out how to early exit if point count is less than 3
      let point_count =
        value_at_frame(point_count, frame, scalar_interpolator())
        |> float.truncate

      let angle_step = { 2.0 *. math.pi() } /. int.to_float(point_count)

      let tangent_length =
        polygon_roundness_tangent_length(radius:, roundness:, point_count:)

      let vertices =
        int.range(from: 0, to: point_count, with: [], run: fn(vertices, i) {
          let angle =
            { int.to_float(i) *. angle_step }
            -. { math.pi() /. 2.0 }
            +. rotation

          let vertex =
            vertex_on_circle(center: position, radius:, angle:, tangent_length:)

          [vertex, ..vertices]
        })
        |> list.reverse

      //TODO: replace assert with early return
      let assert [first, second, third, ..rest] = vertices
      ClosedPath(first:, second:, third:, rest:)
    }
    Path(name:, hidden:, direction:, path:) -> {
      value_at_frame(path, frame, path_interpolator())
    }
  }

  // TODO: explain why each style gets its own path + geometry
  // also explain why we reverse the styles
  list.reverse(styles)
  |> list.filter_map(fn(style) {
    use <- bool.guard(style.hidden, return: Error(Nil))

    let style_attributes = case style {
      Stroke(name:, hidden:, opacity:, width:, color:) -> {
        let color = value_at_frame(color, frame, color_interpolator())
        let opacity = value_at_frame(opacity, frame, scalar_interpolator())
        let width = value_at_frame(width, frame, scalar_interpolator())
        [
          attribute.attribute("stroke", color_to_css(color)),
          attribute.attribute("stroke-opacity", float.to_string(opacity)),
          attribute.attribute("stroke-width", float.to_string(width)),
          attribute.attribute("fill", "none"),
        ]
      }
      Fill(name:, hidden:, fill_rule:, opacity:, color:) -> {
        let color = value_at_frame(color, frame, color_interpolator())
        let opacity = value_at_frame(opacity, frame, scalar_interpolator())
        [
          attribute.attribute("fill", color_to_css(color)),
          attribute.attribute("fill-opacity", float.to_string(opacity)),
          fill_rule_attribute(fill_rule),
          attribute.attribute("stroke", "none"),
        ]
      }
    }

    Ok(svg.path([bezier_path_to_attribute(path), ..style_attributes]))
  })
  |> element.fragment
}

/// Approximation formula taken from the docs
fn polygon_roundness_tangent_length(
  radius radius: Float,
  roundness roundness: Float,
  point_count point_count: Int,
) -> Float {
  case point_count {
    point_count if point_count >= 3 -> {
      let arc_length = 2.0 *. math.pi() *. radius /. int.to_float(point_count)
      arc_length /. 4.0 *. roundness
    }
    _ -> 0.0
  }
}

/// A vertex on a circle at `angle`, with handles tangent to the
/// circle and `tangent_length` long in each direction.
fn vertex_on_circle(
  center center: Vector,
  radius radius: Float,
  angle angle: Float,
  tangent_length tangent_length: Float,
) -> Vertex {
  let direction = Vector(math.cos(angle), math.sin(angle))

  let position = vector_multiply(direction, radius) |> vector_add(center)
  let normal = vector_normal(direction)

  Vertex(
    position:,
    out_tangent: vector_multiply(normal, tangent_length),
    in_tangent: vector_multiply(normal, -1.0 *. tangent_length),
  )
}

fn graphic_element_decoder() -> Decoder(GraphicElement) {
  //TODO: should probably consider an empty string as option.None
  use name <- field_option("nm", decode.string)
  use hidden <- decode.optional_field("hd", False, decode.bool)

  use type_ <- decode.field("ty", decode.string)
  case type_ {
    "el" -> {
      use direction <- decode.optional_field(
        "d",
        Normal,
        shape_direction_decoder(),
      )
      use position <- decode.field("p", position_decoder())
      use size <- decode.field("s", vector_property_decoder())
      Ellipse(name:, hidden:, direction:, position:, size:)
      |> Shape
      |> decode.success
    }
    "rc" -> {
      use direction <- decode.optional_field(
        "d",
        Normal,
        shape_direction_decoder(),
      )
      use position <- decode.field("p", position_decoder())
      use size <- decode.field("s", vector_property_decoder())
      use corner_radius <- decode.field("r", scalar_property_decoder())
      Rectangle(name:, hidden:, direction:, position:, size:, corner_radius:)
      |> Shape
      |> decode.success
    }
    "sr" -> {
      use direction <- decode.optional_field(
        "d",
        Normal,
        shape_direction_decoder(),
      )

      use position <- decode.field("p", position_decoder())
      use rotation <- decode.field("r", scalar_property_decoder())
      use point_count <- decode.field("pt", scalar_property_decoder())
      use outer_radius <- decode.field("or", scalar_property_decoder())
      use outer_roundness <- decode.field("os", scalar_property_decoder())
      use star_type <- decode.optional_field("sy", 1, decode.int)

      case star_type {
        1 -> {
          use inner_radius <- decode.field("ir", scalar_property_decoder())
          use inner_roundness <- decode.field("is", scalar_property_decoder())
          Polystar(
            name:,
            hidden:,
            direction:,
            position:,
            rotation:,
            point_count:,
            outer_radius:,
            outer_roundness:,
            inner_radius:,
            inner_roundness:,
          )
          |> Shape
          |> decode.success
        }
        2 -> {
          RegularPolygon(
            name:,
            hidden:,
            direction:,
            position:,
            rotation:,
            point_count:,
            radius: outer_radius,
            roundness: outer_roundness,
          )
          |> Shape
          |> decode.success
        }
        _ -> decode.success(UnknownElement(name:, type_:))
      }
    }
    "sh" -> {
      use direction <- decode.optional_field(
        "d",
        Normal,
        shape_direction_decoder(),
      )
      use value <- decode.field("ks", path_property_decoder())
      Path(name:, hidden:, direction:, path: value) |> Shape |> decode.success
    }

    "st" -> {
      use opacity <- decode.field("o", scalar_property_decoder())
      use width <- decode.field("w", scalar_property_decoder())
      use color <- decode.field("c", color_property_decoder())
      Stroke(name:, hidden:, opacity:, width:, color:)
      |> Style
      |> decode.success
    }
    "fl" -> {
      use fill_rule <- decode.optional_field("r", NonZero, fill_rule_decoder())
      use opacity <- decode.field("o", scalar_property_decoder())
      use color <- decode.field("c", color_property_decoder())
      Fill(name:, hidden:, fill_rule:, opacity:, color:)
      |> Style
      |> decode.success
    }
    "tr" -> {
      use transform <- decode.then(transform_decoder())
      decode.success(TransformElement(transform:))
    }

    "gr" -> {
      use <- decode.recursive
      use elements <- decode.field(
        "it",
        decode.list(of: graphic_element_decoder()),
      )
      Group(name:, hidden:, elements:) |> decode.success
    }

    type_ ->
      //TODO: at some point this should be a success, but it's a failure rn for development purposes
      // catching misssed types early
      decode.failure(UnknownElement(name:, type_:), expected: "GraphicElement")
  }
}

// fn group_elements_decoder_loop(
//   index: Int,
//   elements: List(GraphicElement),
// ) -> Decoder(#(Transform, List(GraphicElement))) {
//   use type_ <- decode.field(
//     index,
//     decode.field("ty", decode.string, decode.success),
//   )

//   case type_ {
//     "tr" -> {
//       use transform <- decode.field(index, transform_decoder())
//       decode.success(#(transform, list.reverse(elements)))
//     }
//     _ -> {
//       use element <- decode.field(index, graphic_element_decoder())
//       group_elements_decoder_loop(index + 1, [element, ..elements])
//     }
//   }
// }

pub fn from_transform(transform: Transform, frame: Float) -> #(Affine, Float) {
  let anchor_point =
    value_at_frame(transform.anchor_point, frame, vector_interpolator())
  let position = position_at_frame(transform.position, frame)
  let rotation =
    value_at_frame(transform.rotation, frame, scalar_interpolator())
  let scale = value_at_frame(transform.scale, frame, vector_interpolator())
  let skew = value_at_frame(transform.skew, frame, scalar_interpolator())
  let skew_axis =
    value_at_frame(transform.skew_axis, frame, scalar_interpolator())

  let affine =
    affine.translation(-1.0 *. anchor_point.x, -1.0 *. anchor_point.y)
    |> affine.multiply(affine.scaling(scale.x /. 100.0, scale.y /. 100.0), _)
    |> fn(aff) {
      case skew {
        0.0 -> aff
        skew -> {
          let skew = math.to_radians(skew)
          // Lottie conjugates the skew with the axis in the opposite direction
          // from the usual convention, so the axis is negated here.
          let skew_axis = -1.0 *. math.to_radians(skew_axis)

          affine.multiply(affine.skew(skew, skew_axis), aff)
        }
      }
    }
    |> affine.multiply(affine.rotation(math.to_radians(rotation)), _)
    |> affine.multiply(affine.translation(position.x, position.y), _)

  let opacity =
    value_at_frame(transform.opacity, frame, scalar_interpolator()) /. 100.0
  #(affine, opacity)
}

fn position_at_frame(position: Position, frame: Float) -> Vector {
  case position {
    Split(x:, y:) -> {
      let x = value_at_frame(x, frame, scalar_interpolator())
      let y = value_at_frame(y, frame, scalar_interpolator())
      Vector(x, y)
    }
    Joint(position) -> value_at_frame(position, frame, vector_interpolator())
  }
}

/// Lottie stores all rotational values in degrees
fn rotation_at_frame(rotation: Property(Float, Float), frame: Float) -> Float {
  value_at_frame(rotation, frame, scalar_interpolator()) |> math.to_radians
}

/// Lottie stores roundness as a percentage, with 100 being full roundness
fn roundness_at_frame(
  roundness: Property(Float, Float),
  frame: Float,
) -> Float {
  value_at_frame(roundness, frame, scalar_interpolator()) /. 100.0
}

//TODO: use this
/// Lottie stores scale as a percentage, with 100 representing 1x scale
fn scale_at_frame(scale: Property(Vector, Vector), frame: Float) -> Vector {
  value_at_frame(scale, frame, vector_interpolator())
  |> vector_divide(by: 100.0)
}

pub type Transform {
  Transform(
    anchor_point: Property(Vector, Vector),
    position: Position,
    rotation: Property(Float, Float),
    scale: Property(Vector, Vector),
    opacity: Property(Float, Float),
    skew: Property(Float, Float),
    skew_axis: Property(Float, Float),
  )
}

pub type Position {
  Split(x: Property(Float, Float), y: Property(Float, Float))
  Joint(Property(Vector, Vector))
}

const identity_transform = Transform(
  anchor_point: Static(Vector(0.0, 0.0)),
  position: Joint(Static(Vector(0.0, 0.0))),
  rotation: Static(0.0),
  scale: Static(Vector(100.0, 100.0)),
  opacity: Static(100.0),
  skew: Static(0.0),
  skew_axis: Static(0.0),
)

pub fn transform_decoder() -> Decoder(Transform) {
  use anchor_point <- decode.optional_field(
    "a",
    Static(Vector(0.0, 0.0)),
    vector_property_decoder(),
  )
  use position <- decode.optional_field(
    "p",
    Joint(Static(Vector(0.0, 0.0))),
    position_decoder(),
  )
  use rotation <- decode.optional_field(
    "r",
    Static(0.0),
    scalar_property_decoder(),
  )
  use scale <- decode.optional_field(
    "s",
    Static(Vector(100.0, 100.0)),
    vector_property_decoder(),
  )
  use opacity <- decode.optional_field(
    "o",
    Static(100.0),
    scalar_property_decoder(),
  )
  use skew <- decode.optional_field(
    "sk",
    Static(0.0),
    scalar_property_decoder(),
  )
  use skew_axis <- decode.optional_field(
    "sa",
    Static(0.0),
    scalar_property_decoder(),
  )
  decode.success(Transform(
    anchor_point:,
    position:,
    rotation:,
    scale:,
    opacity:,
    skew:,
    skew_axis:,
  ))
}

fn field_option(
  key: name,
  field_decoder: Decoder(t),
  next: fn(Option(t)) -> Decoder(final),
) -> Decoder(final) {
  decode.optional_field(key, option.None, decode.optional(field_decoder), next)
}

//TODO: look into if an iv array is necessary here instead of a dict
// reason being that in order to interpolate values properly you need to know the current keyframe and the next keyframe
// and since dicts are not ordered you cannot easily get the "next" keyframe
//TODO: also idk if this should be generic if it's fundamentally a closed set idk
pub type Property(value, easing) {
  Static(value)
  //TODO: can probably switch this to a list and use a binary search tree to get O(logn) time complexity insteasd of iv + traditional binary search
  // Animated(iv.Array(Keyframe(value, easing)))
  // Animated(List(Keyframe(value, easing)))
  Animated(first: Keyframe(value, easing), rest: List(Keyframe(value, easing)))
}

//TODO: finish this and start using value_at_time for basic compilation stuff
//TODO: finish this and start using value_at_time for basic compilation stuff
//TODO: finish this and start using value_at_time for basic compilation stuff
//TODO: finish this and start using value_at_time for basic compilation stuff
//TODO: finish this and start using value_at_time for basic compilation stuff
//TODO: finish this and start using value_at_time for basic compilation stuff
//TODO: finish this and start using value_at_time for basic compilation stuff
pub type Interpolator(value, easing) {
  Interpolator(
    ease: fn(Float, Easing(easing), Easing(easing)) -> easing,
    lerp: fn(easing, value, value) -> value,
  )
}

pub fn value_at_frame(
  property: Property(value, easing),
  frame: Float,
  interpolator: Interpolator(value, easing),
) -> value {
  case property {
    Static(value) -> value
    Animated(first:, rest:) ->
      find_value_at_frame_loop(first, rest, frame, interpolator)
  }
}

fn find_value_at_frame_loop(
  start: Keyframe(value, easing),
  rest: List(Keyframe(value, easing)),
  frame: Float,
  interpolator: Interpolator(value, easing),
) -> value {
  use <- bool.guard(start.frame >=. frame, return: start.value)

  case rest {
    [end, ..rest] ->
      case end.frame >. frame {
        True -> {
          use <- bool.guard(start.hold, return: start.value)

          let x = { frame -. start.frame } /. { end.frame -. start.frame }
          let y = interpolator.ease(x, start.out_tangent, start.in_tangent)

          let value = interpolator.lerp(y, start.value, end.value)
          value
        }
        False -> find_value_at_frame_loop(end, rest, frame, interpolator)
      }
    [] -> start.value
  }
}

pub fn scalar_interpolator() -> Interpolator(Float, Float) {
  Interpolator(
    ease: fn(x, out_tangent, in_tangent) {
      let t = newton_raphson(x, out_tangent.x, in_tangent.x)
      cubic_bezier(t, out_tangent.y, in_tangent.y)
    },
    lerp:,
  )
}

pub fn vector_interpolator() -> Interpolator(Vector, Vector) {
  Interpolator(
    ease: fn(x, out_tangent: Easing(Vector), in_tangent: Easing(Vector)) {
      let yx = {
        let t = newton_raphson(x, out_tangent.x.x, in_tangent.x.x)
        cubic_bezier(t, out_tangent.y.x, in_tangent.y.x)
      }

      let yy = {
        let t = newton_raphson(x, out_tangent.x.y, in_tangent.x.y)
        cubic_bezier(t, out_tangent.y.y, in_tangent.y.y)
      }

      Vector(yx, yy)
    },
    lerp: fn(t, start: Vector, end: Vector) {
      let x = lerp(t.x, start.x, end.x)
      let y = lerp(t.y, start.y, end.y)
      Vector(x, y)
    },
  )
}

pub fn color_interpolator() -> Interpolator(Color, Float) {
  Interpolator(
    ease: fn(x, out_tangent, in_tangent) {
      let t = newton_raphson(x, out_tangent.x, in_tangent.x)
      cubic_bezier(t, out_tangent.y, in_tangent.y)
    },
    lerp: fn(t, start: Color, end: Color) {
      let r = lerp(t, start.r, end.r)
      let g = lerp(t, start.g, end.g)
      let b = lerp(t, start.b, end.b)
      let a = lerp(t, start.a, end.a)
      Color(r:, g:, b:, a:)
    },
  )
}

pub fn path_interpolator() -> Interpolator(Path, Float) {
  Interpolator(
    ease: fn(x, out_tangent, in_tangent) {
      let t = newton_raphson(x, out_tangent.x, in_tangent.x)
      cubic_bezier(t, out_tangent.y, in_tangent.y)
    },
    lerp: fn(t, start: Path, end: Path) {
      case start, end {
        OpenPath(..), OpenPath(..) -> {
          let first = vertex_lerp(t, start.first, end.first)
          let second = vertex_lerp(t, start.second, end.second)
          let rest = case list.strict_zip(start.rest, end.rest) {
            Ok(vertex_pairs) ->
              list.map(vertex_pairs, fn(pair) {
                let #(start, end) = pair
                vertex_lerp(t, start, end)
              })
            Error(Nil) -> end.rest
          }
          OpenPath(first:, second:, rest:)
        }
        ClosedPath(..), ClosedPath(..) -> {
          let first = vertex_lerp(t, start.first, end.first)
          let second = vertex_lerp(t, start.second, end.second)
          let third = vertex_lerp(t, start.third, end.third)
          let rest = case list.strict_zip(start.rest, end.rest) {
            Ok(vertex_pairs) ->
              list.map(vertex_pairs, fn(pair) {
                let #(start, end) = pair
                vertex_lerp(t, start, end)
              })
            Error(Nil) -> end.rest
          }
          ClosedPath(first:, second:, third:, rest:)
        }
        _, _ -> end
      }
    },
  )
}

fn vertex_lerp(t: Float, a: Vertex, b: Vertex) -> Vertex {
  let position = vector_lerp(t, a.position, b.position)
  let out_tangent = vector_lerp(t, a.out_tangent, b.out_tangent)
  let in_tangent = vector_lerp(t, a.in_tangent, b.in_tangent)
  Vertex(position:, out_tangent:, in_tangent:)
}

fn vector_lerp(t: Float, a: Vector, b: Vector) -> Vector {
  let x = lerp(t, a.x, b.x)
  let y = lerp(t, a.y, b.y)
  Vector(x, y)
}

fn lerp(t: Float, a: Float, b: Float) -> Float {
  t *. { b -. a } +. a
}

fn newton_raphson(x: Float, a0: Float, a1: Float) -> Float {
  // x itself is a reasonable initial guess for t
  newton_raphson_loop(x, x, a0, a1, 0)
}

fn newton_raphson_loop(
  x: Float,
  t: Float,
  a0: Float,
  a1: Float,
  i: Int,
) -> Float {
  let max_iterations = 8
  let epsilon = 0.0001

  case i >= max_iterations {
    True -> t
    False -> {
      let fx = cubic_bezier(t, a0, a1) -. x

      case float.absolute_value(fx) <. epsilon {
        True -> t
        False -> {
          let dfx = cubic_bezier_derivative(t, a0, a1)

          case float.absolute_value(dfx) <. 0.000001 {
            // derivative too flat, bail out to avoid a huge/unstable step
            True -> t
            False -> {
              let t1 = t -. fx /. dfx
              newton_raphson_loop(x, t1, a0, a1, i + 1)
            }
          }
        }
      }
    }
  }
}

fn cubic_bezier(t: Float, a0: Float, a1: Float) -> Float {
  let t2 = t *. t
  let t3 = t2 *. t
  let mt = 1.0 -. t

  { 3.0 *. mt *. mt *. t *. a0 } +. { 3.0 *. mt *. t2 *. a1 } +. t3
}

fn cubic_bezier_derivative(t: Float, a0: Float, a1: Float) -> Float {
  let mt = 1.0 -. t

  { 3.0 *. mt *. mt *. a0 }
  +. { 6.0 *. mt *. t *. { a1 -. a0 } }
  +. { 3.0 *. t *. t *. { 1.0 -. a1 } }
}

pub fn position_decoder() -> Decoder(Position) {
  use splittable <- decode.optional_field("s", False, decode.bool)

  case splittable {
    True -> {
      use x <- decode.field("x", scalar_property_decoder())
      use y <- decode.field("y", scalar_property_decoder())
      decode.success(Split(x:, y:))
    }
    False -> {
      use value <- decode.then(vector_property_decoder())
      decode.success(Joint(value))
    }
  }
}

pub fn vector_property_decoder() -> Decoder(Property(Vector, Vector)) {
  property_decoder(
    vector_decoder(),
    vector_easing_decoder(),
    Vector(0.0, 0.0),
    Easing(x: Vector(0.0, 0.0), y: Vector(0.0, 0.0)),
    Easing(x: Vector(1.0, 1.0), y: Vector(1.0, 1.0)),
  )
}

pub fn scalar_property_decoder() -> Decoder(Property(Float, Float)) {
  property_decoder(
    scalar_decoder(),
    scalar_easing_decoder(),
    0.0,
    Easing(x: 0.0, y: 0.0),
    Easing(x: 1.0, y: 1.0),
  )
}

pub fn gradient_property_decoder() -> Decoder(Property(Gradient, Float)) {
  use color_stop_count <- decode.field("p", decode.int)
  // unlike the other properties, this is nested since the top level object needs to store the color stop count
  decode.at(
    ["k"],
    property_decoder(
      gradient_decoder(color_stop_count),
      scalar_easing_decoder(),
      zero_gradient,
      Easing(x: 0.0, y: 0.0),
      Easing(x: 1.0, y: 1.0),
    ),
  )
}

pub fn color_property_decoder() -> Decoder(Property(Color, Float)) {
  property_decoder(
    color_decoder(),
    scalar_easing_decoder(),
    zero_color,
    Easing(x: 0.0, y: 0.0),
    Easing(x: 1.0, y: 1.0),
  )
}

pub fn path_property_decoder() -> Decoder(Property(Path, Float)) {
  property_decoder(
    bezier_path_decoder(),
    scalar_easing_decoder(),
    zero_bezier_path,
    Easing(x: 0.0, y: 0.0),
    Easing(x: 1.0, y: 1.0),
  )
}

pub fn property_decoder(
  value_decoder: Decoder(value),
  easing_decoder: Decoder(Easing(easing)),
  default_value: value,
  default_out_tangent: Easing(easing),
  default_in_tangent: Easing(easing),
) -> Decoder(Property(value, easing)) {
  let static_property_decoder = {
    use value <- decode.field("k", value_decoder)
    decode.success(Static(value))
  }

  let animated_property_decoder = {
    use keyframes <- decode.field("k", {
      decode.list(of: keyframe_decoder(
        value_decoder,
        easing_decoder,
        default_out_tangent,
        default_in_tangent,
      ))
    })
    case keyframes {
      [first, ..rest] -> decode.success(Animated(first:, rest:))
      _ -> decode.failure(Static(default_value), "Property")
    }
  }

  // the spec mandates that the "a" (animated) flag field is present on every property.
  // in practice several exporters omit it, so we're forced to infer whether the property is animated from its structure.
  // decode.one_of(static_property_decoder, [animated_property_decoder])
  decode.one_of(animated_property_decoder, [static_property_decoder])
}

pub type Keyframe(value, easing) {
  Keyframe(
    frame: Float,
    value: value,
    hold: Bool,
    out_tangent: Easing(easing),
    in_tangent: Easing(easing),
  )
}

pub fn keyframe_decoder(
  value_decoder: Decoder(value),
  easing_decoder: Decoder(Easing(easing)),
  default_out_tangent: Easing(easing),
  default_in_tangent: Easing(easing),
) -> Decoder(Keyframe(value, easing)) {
  use frame <- decode.field("t", decode.float)
  use value <- decode.field("s", value_decoder)
  use hold <- decode.optional_field("h", False, integer_boolean_decoder())
  use out_tangent <- decode.optional_field(
    "o",
    default_out_tangent,
    easing_decoder,
  )
  use in_tangent <- decode.optional_field(
    "i",
    default_in_tangent,
    easing_decoder,
  )

  decode.success(Keyframe(frame:, value:, hold:, out_tangent:, in_tangent:))
}

pub type Easing(shape) {
  Easing(x: shape, y: shape)
}

pub fn scalar_easing_decoder() -> Decoder(Easing(Float)) {
  use x <- decode.field("x", scalar_decoder())
  // "Unlike x values, y values are not clamped to [0 .. 1]. Supernormal y values allow the interpolated value
  // to overshoot (extrapolate) beyond the specified keyframe values range."
  use y <- decode.field("y", scalar_decoder())
  decode.success(Easing(x:, y:))
}

pub fn vector_easing_decoder() -> Decoder(Easing(Vector)) {
  use x <- decode.field("x", vector_decoder())
  use y <- decode.field("y", vector_decoder())
  decode.success(Easing(x:, y:))
}

fn scalar_decoder() -> Decoder(Float) {
  decode.one_of(decode.float, or: [decode.at([0], decode.float)])
}

pub fn integer_boolean_decoder() -> Decoder(Bool) {
  use value <- decode.then(decode.int)

  case value {
    0 -> decode.success(False)
    1 -> decode.success(True)
    _ -> decode.failure(False, expected: "Bool")
  }
}

pub type Color {
  Color(r: Float, g: Float, b: Float, a: Float)
}

const zero_color = Color(r: 0.0, g: 0.0, b: 0.0, a: 0.0)

fn color_to_css(color: Color) -> String {
  let Color(r:, g:, b:, a:) = color
  "rgb("
  <> float.to_string(r *. 255.0)
  <> " "
  <> float.to_string(g *. 255.0)
  <> " "
  <> float.to_string(b *. 255.0)
  <> " / "
  <> float.to_string(a)
  <> ")"
}

// pub fn color_decoder() -> Decoder(Color) {
//   use value <- decode.then(decode.list(of: normalized_decoder()))

//   case value {
//     [r, g, b] -> decode.success(Color(r:, g:, b:))
//     //TODO: cavalry supports alpha so might want to test animating it and see if it reflects in the lottie export
//     // "Note: sometimes you might find color values with 4 components (the 4th being alpha) but most players ignore the last component."
//     [r, g, b, _] -> decode.success(Color(r:, g:, b:))
//     _ -> decode.failure(Color(r: 0.0, g: 0.0, b: 0.0), expected: "Color")
//   }
// }

pub fn color_decoder() -> Decoder(Color) {
  use r <- decode.field(0, scalar_decoder())
  use g <- decode.field(1, scalar_decoder())
  use b <- decode.field(2, scalar_decoder())
  use a <- decode.optional_field(3, 1.0, scalar_decoder())
  decode.success(Color(r:, g:, b:, a:))
}

pub type Gradient {
  Gradient(
    color_stops: List(#(Float, Color)),
    transparency_stops: List(#(Float, Float)),
  )
}

const zero_gradient = Gradient(color_stops: [], transparency_stops: [])

pub fn gradient_decoder(color_stop_count: Int) -> Decoder(Gradient) {
  use data <- decode.then(decode.list(of: scalar_decoder()))
  let transparency_stop_count = { list.length(data) - 4 * color_stop_count } / 2

  let gradient = {
    use #(color_stops, data) <- result.try(
      parse_color_stops_loop(color_stop_count, data, []),
    )
    use transparency_stops <- result.try(
      parse_transparency_stops_loop(transparency_stop_count, data, []),
    )

    Ok(Gradient(color_stops:, transparency_stops:))
  }

  case gradient {
    Ok(gradient) -> decode.success(gradient)
    Error(Nil) ->
      decode.failure(
        Gradient(color_stops: [], transparency_stops: []),
        "Gradient",
      )
  }
}

fn parse_color_stops_loop(
  stop_count: Int,
  data: List(Float),
  color_stops: List(#(Float, Color)),
) -> Result(#(List(#(Float, Color)), List(Float)), Nil) {
  case stop_count {
    0 -> Ok(#(list.reverse(color_stops), data))
    stop_count ->
      case data {
        [position, r, g, b, ..rest] -> {
          let stop = #(position, Color(r:, g:, b:, a: 1.0))
          parse_color_stops_loop(stop_count - 1, rest, [stop, ..color_stops])
        }
        _ -> Error(Nil)
      }
  }
}

fn parse_transparency_stops_loop(
  stop_count: Int,
  data: List(Float),
  transparency_stops: List(#(Float, Float)),
) -> Result(List(#(Float, Float)), Nil) {
  case stop_count {
    0 -> Ok(list.reverse(transparency_stops))
    stop_count ->
      case data {
        [position, alpha, ..rest] -> {
          let stop = #(position, alpha)
          parse_transparency_stops_loop(stop_count - 1, rest, [
            stop,
            ..transparency_stops
          ])
        }
        _ -> Error(Nil)
      }
  }
}

pub fn hex_color_decoder() -> Decoder(Color) {
  use value <- decode.then(decode.string)

  let color = {
    use hex <- result.try(case value {
      "#" <> value -> Ok(value)
      _ -> Error(Nil)
    })

    use #(r1, hex) <- result.try(parse_hex_digit(hex))
    use #(r2, hex) <- result.try(parse_hex_digit(hex))
    use #(g1, hex) <- result.try(parse_hex_digit(hex))
    use #(g2, hex) <- result.try(parse_hex_digit(hex))
    use #(b1, hex) <- result.try(parse_hex_digit(hex))
    use #(b2, hex) <- result.try(parse_hex_digit(hex))
    use <- bool.guard(hex != "", return: Error(Nil))

    let r = { r2 +. r1 *. 16.0 } /. 255.0
    let g = { g2 +. g1 *. 16.0 } /. 255.0
    let b = { b2 +. b1 *. 16.0 } /. 255.0

    Ok(Color(r:, g:, b:, a: 1.0))
  }

  case color {
    Ok(color) -> decode.success(color)
    Error(Nil) ->
      decode.failure(Color(r: 0.0, g: 0.0, b: 0.0, a: 0.0), expected: "Color")
  }
}

fn parse_hex_digit(hex: String) -> Result(#(Float, String), Nil) {
  case hex {
    "0" <> rest -> Ok(#(0.0, rest))
    "1" <> rest -> Ok(#(1.0, rest))
    "2" <> rest -> Ok(#(2.0, rest))
    "3" <> rest -> Ok(#(3.0, rest))
    "4" <> rest -> Ok(#(4.0, rest))
    "5" <> rest -> Ok(#(5.0, rest))
    "6" <> rest -> Ok(#(6.0, rest))
    "7" <> rest -> Ok(#(7.0, rest))
    "8" <> rest -> Ok(#(8.0, rest))
    "9" <> rest -> Ok(#(9.0, rest))
    "a" <> rest -> Ok(#(10.0, rest))
    "b" <> rest -> Ok(#(11.0, rest))
    "c" <> rest -> Ok(#(12.0, rest))
    "d" <> rest -> Ok(#(13.0, rest))
    "e" <> rest -> Ok(#(14.0, rest))
    "f" <> rest -> Ok(#(15.0, rest))
    "A" <> rest -> Ok(#(10.0, rest))
    "B" <> rest -> Ok(#(11.0, rest))
    "C" <> rest -> Ok(#(12.0, rest))
    "D" <> rest -> Ok(#(13.0, rest))
    "E" <> rest -> Ok(#(14.0, rest))
    "F" <> rest -> Ok(#(15.0, rest))
    _ -> Error(Nil)
  }
}

//prob rename to Vector2 to make it clear this only has 2 components
pub type Vector {
  Vector(x: Float, y: Float)
}

const zero_vector = Vector(x: 0.0, y: 0.0)

fn vector_multiply(a: Vector, by s: Float) -> Vector {
  Vector(a.x *. s, a.y *. s)
}

fn vector_add(a: Vector, b: Vector) -> Vector {
  Vector(a.x +. b.x, a.y +. b.y)
}

fn vector_divide(a: Vector, by s: Float) -> Vector {
  Vector(a.x /. s, a.y /. s)
}

fn vector_midpoint(a: Vector, b: Vector) -> Vector {
  let x = { a.x +. b.x } /. 2.0
  let y = { a.y +. b.y } /. 2.0
  Vector(x, y)
}

fn vector_normal(a: Vector) -> Vector {
  Vector(-1.0 *. a.y, a.x)
}

pub fn vector_decoder() -> Decoder(Vector) {
  let full_vector_decoder = {
    use x <- decode.field(0, decode.float)
    use y <- decode.field(1, decode.float)
    decode.success(Vector(x:, y:))
  }

  let single_element_array_decoder = {
    use x <- decode.field(0, decode.float)
    decode.success(Vector(x:, y: x))
  }

  let scalar_decoder = {
    use value <- decode.then(decode.float)
    decode.success(Vector(x: value, y: value))
  }

  decode.one_of(full_vector_decoder, [
    single_element_array_decoder,
    scalar_decoder,
  ])
}

pub type Path {
  /// An open path needs at least 2 vertices to be considered valid.
  OpenPath(first: Vertex, second: Vertex, rest: List(Vertex))
  /// A closed path needs at least 3 vertices to be considered valid.
  ClosedPath(first: Vertex, second: Vertex, third: Vertex, rest: List(Vertex))
}

// const zero_bezier_path = BezierPath(closed: False, vertices: [])
const zero_bezier_path = OpenPath(
  first: zero_vertex,
  second: zero_vertex,
  rest: [],
)

//TODO: rename point to position
pub type Vertex {
  Vertex(position: Vector, out_tangent: Vector, in_tangent: Vector)
}

const zero_vertex = Vertex(
  position: zero_vector,
  out_tangent: zero_vector,
  in_tangent: zero_vector,
)

fn bezier_path_to_attribute(path: Path) -> Attribute(Message) {
  case path {
    OpenPath(first:, second:, rest:) -> {
      let value = "M " <> vector_to_svg(first.position) <> curve(first, second)

      let #(_, value) =
        list.fold(rest, from: #(second, value), with: fn(acc, end) {
          let #(start, value) = acc

          let segment = curve(start, end)
          #(end, value <> segment)
        })

      attribute.attribute("d", value)
    }
    ClosedPath(first:, second:, third:, rest:) -> {
      let value =
        "M "
        <> vector_to_svg(first.position)
        <> curve(first, second)
        <> curve(second, third)

      let #(last, value) =
        list.fold(rest, from: #(third, value), with: fn(acc, end) {
          let #(start, value) = acc

          let segment = curve(start, end)
          #(end, value <> segment)
        })

      let value = value <> curve(last, first) <> " Z"

      attribute.attribute("d", value)
    }
  }
}

fn curve(start: Vertex, end: Vertex) -> String {
  " C "
  <> vector_to_svg(start.out_tangent |> vector_add(start.position))
  <> ", "
  <> vector_to_svg(end.in_tangent |> vector_add(end.position))
  <> ", "
  <> vector_to_svg(end.position)
}

fn vector_to_svg(vector: Vector) -> String {
  float.to_string(vector.x) <> " " <> float.to_string(vector.y)
}

pub fn bezier_path_decoder() -> Decoder(Path) {
  use closed <- decode.optional_field("c", False, decode.bool)
  use positions <- decode.field("v", decode.list(of: vector_decoder()))
  use out_tangents <- decode.field("o", decode.list(of: vector_decoder()))
  use in_tangents <- decode.field("i", decode.list(of: vector_decoder()))

  let vertices =
    build_vertices_loop(positions, out_tangents, in_tangents, built: [])

  case closed, vertices {
    _, Error(Nil) -> decode.failure(zero_bezier_path, expected: "Path")
    True, Ok(vertices) ->
      case vertices {
        [first, second, third, ..rest] ->
          decode.success(ClosedPath(first:, second:, third:, rest:))
        _ ->
          decode.failure(
            zero_bezier_path,
            expected: "A closed path with at least 3 vertices",
          )
      }
    False, Ok(vertices) ->
      case vertices {
        [first, second, ..rest] ->
          decode.success(OpenPath(first:, second:, rest:))
        _ ->
          decode.failure(
            zero_bezier_path,
            expected: "An open path with at least 2 vertices",
          )
      }
  }
}

fn build_vertices_loop(
  positions: List(Vector),
  out_tangents: List(Vector),
  in_tangents: List(Vector),
  built vertices: List(Vertex),
) -> Result(List(Vertex), Nil) {
  case positions, out_tangents, in_tangents {
    [], [], [] -> Ok(list.reverse(vertices))
    [position, ..positions],
      [out_tangent, ..out_tangents],
      [in_tangent, ..in_tangents]
    -> {
      let vertex = Vertex(position:, out_tangent:, in_tangent:)
      build_vertices_loop(positions, out_tangents, in_tangents, [
        vertex,
        ..vertices
      ])
    }
    // all lists must have the same lengthh
    [], _, _ | _, [], _ | _, _, [] -> Error(Nil)
  }
}
