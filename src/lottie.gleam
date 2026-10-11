import dummy
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

const circle_path = BezierPath(
  closed: True,
  // Right
  first: Vertex(
    position: Vector(200.0, 100.0),
    in_tangent: Vector(0.0, -55.228475),
    out_tangent: Vector(0.0, 55.228475),
  ),
  // Bottom
  second: Vertex(
    position: Vector(100.0, 200.0),
    in_tangent: Vector(55.228475, 0.0),
    out_tangent: Vector(-55.228475, 0.0),
  ),
  rest: [
    // Left
    Vertex(
      position: Vector(0.0, 100.0),
      in_tangent: Vector(0.0, 55.228475),
      out_tangent: Vector(0.0, -55.228475),
    ),
    // Top
    Vertex(
      position: Vector(100.0, 0.0),
      in_tangent: Vector(-55.228475, 0.0),
      out_tangent: Vector(55.228475, 0.0),
    ),
  ],
)

const square_path_string = "{
                      \"c\": true,
                      \"i\": [
                        [
                          0.0,
                          0.0
                        ],
                        [
                          0.0,
                          0.0
                        ],
                        [
                          0.0,
                          0.0
                        ],
                        [
                          0.0,
                          0.0
                        ]
                      ],
                      \"o\": [
                        [
                          0.0,
                          0.0
                        ],
                        [
                          0.0,
                          0.0
                        ],
                        [
                          0.0,
                          0.0
                        ],
                        [
                          0.0,
                          0.0
                        ]
                      ],
                      \"v\": [
                        [
                          -400.0,
                          400.0
                        ],
                        [
                          400.0,
                          400.0
                        ],
                        [
                          400.0,
                          -400.0
                        ],
                        [
                          -400.0,
                          -400.0
                        ]
                      ]
                  }"

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
  Model(animation: Option(Animation))
}

pub type Message {
  ReturnedAnimation(Result(Animation, rsvp.Error(String)))
}

pub fn init(_args: Nil) -> #(Model, Effect(Message)) {
  let fetch_animation =
    rsvp.get(
      // "/Basic_Comp.json",
      "/Lottiefiles_Basic_Comp.json",
      rsvp.expect_json(animation_decoder(), ReturnedAnimation),
    )
  #(Model(animation: option.None), fetch_animation)
}

pub fn update(model: Model, message: Message) -> #(Model, Effect(Message)) {
  case message {
    ReturnedAnimation(animation) ->
      case animation {
        Ok(animation) -> #(
          Model(animation: option.Some(animation)),
          effect.none(),
        )
        Error(_) -> #(model, effect.none())
      }
  }
}

pub fn view(model: Model) -> Element(Message) {
  case model.animation {
    option.Some(animation) -> {
      compile(animation, 0.0)
    }
    option.None -> element.none()
  }
  // html.svg(
  //   [
  //     attribute.width(300),
  //     attribute.height(300),
  //   ],
  //   [
  //     svg.rect([
  //       attribute.width(300),
  //       attribute.height(300),
  //       attribute.attribute("fill", "#0000ff"),
  //       attribute.attribute("fill", "#00ff00"),
  //       attribute.attribute("fill", "#ff0000"),
  //     ]),
  //     // svg.path([
  //   //   bezier_path_to_attribute(circle_path),
  //   //   // attribute.attribute("fill", "#0000ff"),
  //   //   attribute.attribute("fill", "none"),
  //   //   attribute.attribute("stroke", "#0000ff"),
  //   // ]),
  //   ],
  // )
}

pub fn compile(animation: Animation, time: Float) -> Element(Message) {
  html.svg(
    [attribute.width(animation.width), attribute.height(animation.height)],
    // the first element in lottie has the highest z-index
    // the last element in svg has the highest z index
    list.reverse(animation.layers)
      |> list.map(fn(layer) {
        compile_layer(layer, animation.index_to_layer, time)
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
  time: Float,
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
          compile_visual_layer(layer, parent_transform, time)
        option.None -> compile_visual_layer(layer, identity_transform, time)
      }
    }
    DataLayer -> element.none()
  }
}

fn compile_visual_layer(
  layer: VisualLayer,
  parent_transform: Transform,
  time: Float,
) -> Element(Message) {
  let parent_affine = from_transform(parent_transform, time)
  let child_affine = from_transform(layer.transform, time)
  let final_affine = affine.multiply(parent_affine, child_affine)

  svg.g([affine.to_attribute(final_affine)], [
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
      ) ->
      list.map(elements, fn(element) {
        compile_graphic_element(element, time)
      })
      |> element.fragment
    },
  ])
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

// pub fn layer_decoder() -> Decoder(Layer) {
//   use base <- decode.then(base_layer_decoder())
//   use type_ <- decode.field("ty", decode.int)
//   case type_ {
//     3 -> {
//       use transform <- decode.field("ks", transform_decoder())
//       decode.success(NullLayer(base:, transform:))
//     }
//     4 -> {
//       use transform <- decode.field("ks", transform_decoder())
//       decode.success(ShapeLayer(base:, transform:))
//     }
//     _ -> decode.failure(UnsupportedLayer, expected: "Layer")
//   }
// }

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
    roundness: Property(Float, Float),
  )
  Ellipse(
    name: Option(String),
    hidden: Bool,
    direction: ShapeDirection,
    position: Position,
    size: Property(Vector, Vector),
  )
  Path(
    name: Option(String),
    hidden: Bool,
    direction: ShapeDirection,
    path: Property(BezierPath, Float),
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

// if you have [rect, circle, fill, ellipse, stroke, transform]
fn compile_graphic_element(
  element: GraphicElement,
  time: Float,
) -> Element(Message) {
  case element {
    Group(name:, hidden:, elements:) -> compile_group_loop(elements, time)
    _ -> element.none()
  }
}

// [rect, circle, fill, ellipse, stroke, transform]
// 
fn compile_group_loop(
  elements: List(GraphicElement),
  time: Float,
) -> Element(Message) {
  // groups need to be evaluated bottom up
  case list.reverse(elements) {
    [TransformElement(transform:), ..elements] -> {
      let #(children, _) =
        list.fold(elements, from: #([], []), with: fn(acc, element) {
          let #(children, styles) = acc
          case element {
            Shape(shape) -> {
              let child = compile_shape(shape, styles, time)
              #([child, ..children], styles)
            }
            Style(style) -> #(children, [style, ..styles])
            TransformElement(transform:) -> acc
            Group(name:, hidden:, elements:) -> {
              //TODO: im pretty sure that the group needs to take in styles from its parent
              // so should probably make compile_group_loop and pass styles down to that
              let child = compile_group_loop(elements, time)
              #([child, ..children], styles)
            }
            UnknownElement(name:, type_:) -> acc
          }
        })

      svg.g([from_transform(transform, time) |> affine.to_attribute], children)
    }
    _ -> element.none()
  }
}

// fn compile_shape(
//   shape: Shape,
//   styles: List(Style),
//   time: Float,
// ) -> Element(Message) {
//   echo styles
//   use <- bool.guard(shape.hidden, return: element.none())

//   //TODO: see if i need to reverse this, it might be in the wrong order by default if i want to apply the styles in discovery order
//   let style_attributes =
//     list.reverse(styles)
//     |> list.filter(fn(style) { !style.hidden })
//     |> list.flat_map(fn(style) {
//       case style {
//         Stroke(name:, hidden:, opacity:, width:, color:) -> {
//           let color = value_at_time(color, time, color_interpolator())
//           let opacity = value_at_time(opacity, time, scalar_interpolator())
//           let width = value_at_time(width, time, scalar_interpolator())
//           [
//             attribute.attribute("stroke", color_to_css(color)),
//             attribute.attribute("stroke-opacity", float.to_string(opacity)),
//             attribute.attribute("stroke-width", float.to_string(width)),
//             // attribute.attribute("fill", "none"),
//           ]
//         }
//         Fill(name:, hidden:, fill_rule:, opacity:, color:) -> {
//           let color = value_at_time(color, time, color_interpolator())
//           let opacity = value_at_time(opacity, time, scalar_interpolator())
//           [
//             attribute.attribute("fill", color_to_css(color)),
//             attribute.attribute("fill-opacity", float.to_string(opacity)),
//             fill_rule_attribute(fill_rule),
//             // attribute.attribute("stroke", "none"),
//           ]
//         }
//       }
//     })

//   case shape {
//     Rectangle(name:, hidden:, position:, size:, roundness:, direction:) -> {
//       let position = position_at_time(position, time)
//       let size = value_at_time(size, time, vector_interpolator())
//       let roundness = value_at_time(roundness, time, scalar_interpolator())
//       svg.rect(
//         [
//           // svg rectangles are positioned by their top-left corner, but lottie positions rectangles by
//           // their center. so we offset by size / 2 to account for this.
//           attribute.attribute("x", float.to_string(position.x -. size.x /. 2.0)),
//           attribute.attribute("y", float.to_string(position.y -. size.y /. 2.0)),
//           attribute.attribute("width", float.to_string(size.x)),
//           attribute.attribute("height", float.to_string(size.y)),
//           attribute.attribute("rx", float.to_string(roundness)),
//           attribute.attribute("ry", float.to_string(roundness)),
//         ]
//         |> list.append(style_attributes),
//       )
//     }
//     Ellipse(name:, hidden:, position:, size:, direction:) -> {
//       let position = position_at_time(position, time)
//       let size = value_at_time(size, time, vector_interpolator())
//       svg.ellipse(
//         [
//           attribute.attribute("cx", float.to_string(position.x)),
//           attribute.attribute("cy", float.to_string(position.y)),
//           // radius is size / 2
//           attribute.attribute("rx", float.to_string(size.x /. 2.0)),
//           attribute.attribute("ry", float.to_string(size.y /. 2.0)),
//         ]
//         |> list.append(style_attributes),
//       )
//     }
//     //TODO: need to set fill to none if using stroke
//     Path(name:, hidden:, direction:, path:) -> {
//       let path = value_at_time(path, time, path_interpolator())
//       svg.path(
//         [bezier_path_to_attribute(path)]
//         |> list.append(style_attributes),
//       )
//     }
//   }
// }

// Approximation constant for a cubic bezier circle
const k = 0.5522847498

fn compile_shape(
  shape: Shape,
  styles: List(Style),
  time: Float,
) -> Element(Message) {
  use <- bool.guard(shape.hidden, return: element.none())

  let path = case shape {
    Rectangle(name:, hidden:, direction:, position:, size:, roundness:) -> {
      let position = position_at_time(position, time)
      let size = value_at_time(size, time, vector_interpolator())
      let roundness = value_at_time(roundness, time, scalar_interpolator())

      let x_radius = size.x /. 2.0
      let y_radius = size.y /. 2.0

      let left = position.x -. x_radius
      let top = position.y -. y_radius
      let right = position.x +. x_radius
      let bottom = position.y +. y_radius

      let roundness = float.min(roundness, float.min(x_radius, y_radius))
      let kr = k *. roundness

      let top_left_start =
        Vertex(
          position: Vector(left, top +. roundness),
          out_tangent: Vector(0.0, -1.0 *. kr),
          in_tangent: Vector(0.0, 0.0),
        )

      let top_left_end =
        Vertex(
          position: Vector(left +. roundness, top),
          out_tangent: Vector(0.0, 0.0),
          in_tangent: Vector(-1.0 *. kr, 0.0),
        )

      let top_right_start =
        Vertex(
          position: Vector(right -. roundness, top),
          out_tangent: Vector(kr, 0.0),
          in_tangent: Vector(0.0, 0.0),
        )

      let top_right_end =
        Vertex(
          position: Vector(right, top +. roundness),
          out_tangent: Vector(0.0, 0.0),
          in_tangent: Vector(0.0, -1.0 *. kr),
        )

      let bottom_right_start =
        Vertex(
          position: Vector(right, bottom -. roundness),
          out_tangent: Vector(0.0, kr),
          in_tangent: Vector(0.0, 0.0),
        )

      let bottom_right_end =
        Vertex(
          position: Vector(right -. roundness, bottom),
          out_tangent: Vector(0.0, 0.0),
          in_tangent: Vector(kr, 0.0),
        )

      let bottom_left_start =
        Vertex(
          position: Vector(left +. roundness, bottom),
          out_tangent: Vector(-1.0 *. kr, 0.0),
          in_tangent: Vector(0.0, 0.0),
        )

      let bottom_left_end =
        Vertex(
          position: Vector(left, bottom -. roundness),
          out_tangent: Vector(0.0, 0.0),
          in_tangent: Vector(0.0, kr),
        )

      BezierPath(
        closed: True,
        first: top_left_start,
        second: top_left_end,
        rest: [
          top_right_start,
          top_right_end,
          bottom_right_start,
          bottom_right_end,
          bottom_left_start,
          bottom_left_end,
        ],
      )
    }
    Ellipse(name:, hidden:, direction:, position:, size:) -> {
      let position = position_at_time(position, time)
      let size = value_at_time(size, time, vector_interpolator())

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

      BezierPath(closed: True, first: left, second: top, rest: [right, bottom])
    }
    Path(name:, hidden:, direction:, path:) -> {
      value_at_time(path, time, path_interpolator())
    }
  }

  // TODO: explain why each style gets its own path + geometry
  // also explain why we reverse the styles
  list.reverse(styles)
  |> list.filter_map(fn(style) {
    use <- bool.guard(style.hidden, return: Error(Nil))

    let style_attributes = case style {
      Stroke(name:, hidden:, opacity:, width:, color:) -> {
        let color = value_at_time(color, time, color_interpolator())
        let opacity = value_at_time(opacity, time, scalar_interpolator())
        let width = value_at_time(width, time, scalar_interpolator())
        [
          attribute.attribute("stroke", color_to_css(color)),
          attribute.attribute("stroke-opacity", float.to_string(opacity)),
          attribute.attribute("stroke-width", float.to_string(width)),
          attribute.attribute("fill", "none"),
        ]
      }
      Fill(name:, hidden:, fill_rule:, opacity:, color:) -> {
        let color = value_at_time(color, time, color_interpolator())
        let opacity = value_at_time(opacity, time, scalar_interpolator())
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
      use roundness <- decode.field("r", scalar_property_decoder())
      Rectangle(name:, hidden:, direction:, position:, size:, roundness:)
      |> Shape
      |> decode.success
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
      // use #(transform, elements) <- decode.field(
      //   "it",
      //   group_elements_decoder_loop(0, []),
      // )
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

pub fn from_transform(transform: Transform, time: Float) -> Affine {
  let anchor_point =
    value_at_time(transform.anchor_point, time, vector_interpolator())
  let position = position_at_time(transform.position, time)
  let rotation = value_at_time(transform.rotation, time, scalar_interpolator())
  let scale = value_at_time(transform.scale, time, vector_interpolator())
  let skew = value_at_time(transform.skew, time, scalar_interpolator())
  let skew_axis =
    value_at_time(transform.skew_axis, time, scalar_interpolator())

  affine.translation(-1.0 *. anchor_point.x, -1.0 *. anchor_point.y)
  |> affine.multiply(affine.scaling(scale.x /. 100.0, scale.y /. 100.0), _)
  |> fn(aff) {
    case skew {
      0.0 -> aff
      skew -> {
        let #(skew, skew_axis) = #(
          math.to_radians(skew),
          math.to_radians(skew_axis),
        )
        affine.multiply(affine.skew(skew, skew_axis), aff)
      }
    }
  }
  |> affine.multiply(affine.rotation(math.to_radians(rotation)), _)
  |> affine.multiply(affine.translation(position.x, position.y), _)
}

fn position_at_time(position: Position, time: Float) -> Vector {
  case position {
    Split(x:, y:) -> {
      let x = value_at_time(x, time, scalar_interpolator())
      let y = value_at_time(y, time, scalar_interpolator())
      Vector(x, y)
    }
    Joint(position) -> value_at_time(position, time, vector_interpolator())
  }
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

pub fn value_at_time(
  property: Property(value, easing),
  time: Float,
  interpolator: Interpolator(value, easing),
) -> value {
  case property {
    Static(value) -> value
    Animated(first:, rest:) ->
      find_value_at_time_loop(first, rest, time, interpolator)
  }
}

fn find_value_at_time_loop(
  start: Keyframe(value, easing),
  rest: List(Keyframe(value, easing)),
  time: Float,
  interpolator: Interpolator(value, easing),
) -> value {
  use <- bool.guard(start.frame >=. time, return: start.value)

  case rest {
    [end, ..rest] ->
      case end.frame >. time {
        True -> {
          use <- bool.guard(start.hold, return: start.value)

          let x = { time -. start.frame } /. { end.frame -. start.frame }
          let y = interpolator.ease(x, start.out_tangent, end.in_tangent)

          let value = interpolator.lerp(y, start.value, end.value)
          value
        }
        False -> find_value_at_time_loop(end, rest, time, interpolator)
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

//TODO: need to figure out how lerping works between paths of different vertex counts
// on frame 1 the path could have 5 points and frame 30 the path has 10 points
pub fn path_interpolator() -> Interpolator(BezierPath, Float) {
  Interpolator(
    ease: fn(x, out_tangent, in_tangent) {
      let t = newton_raphson(x, out_tangent.x, in_tangent.x)
      cubic_bezier(t, out_tangent.y, in_tangent.y)
    },
    lerp: fn(t, start: BezierPath, end: BezierPath) {
      use <- bool.guard(start.closed != end.closed, return: end)

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

      BezierPath(closed: end.closed, first:, second:, rest:)
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

pub fn path_property_decoder() -> Decoder(Property(BezierPath, Float)) {
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
  use x <- decode.field("x", normalized_decoder())
  // "Unlike x values, y values are not clamped to [0 .. 1]. Supernormal y values allow the interpolated value
  // to overshoot (extrapolate) beyond the specified keyframe values range."
  use y <- decode.field("y", scalar_decoder())
  decode.success(Easing(x:, y:))
}

pub fn vector_easing_decoder() -> Decoder(Easing(Vector)) {
  use x <- decode.field("x", normalized_vector_decoder())
  use y <- decode.field("y", vector_decoder())
  decode.success(Easing(x:, y:))
}

fn normalized_decoder() -> Decoder(Float) {
  use value <- decode.then(scalar_decoder())
  case value {
    value if value <. 0.0 -> decode.success(0.0)
    value if value >. 1.0 -> decode.success(1.0)
    value -> decode.success(value)
  }
  // case value {
  //   value if value >=. 0.0 && value <=. 1.0 -> decode.success(value)
  //   _ -> decode.failure(0.0, expected: "0-1 Float")
  // }
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

// pub type Normalized {
//   Normalized(value: Float)
// }

// pub fn from_float(value: Float) -> Result(Normalized, Nil) {
//   case value {
//     value if value >=. 0.0 && value <=. 1.0 -> Ok(Normalized(value:))
//     _ -> Error(Nil)
//   }
// }

// fn normalized_decoder() -> Decoder(Normalized) {
//   use value <- decode.then(decode.float)
//   case value {
//     value if value >=. 0.0 && value <=. 1.0 -> decode.success(Normalized(value:))
//     _ -> decode.failure(Normalized(0.0), expected: "0-1 Float")
//   }
// }

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
  use r <- decode.field(0, normalized_decoder())
  use g <- decode.field(1, normalized_decoder())
  use b <- decode.field(2, normalized_decoder())
  use a <- decode.optional_field(3, 1.0, normalized_decoder())
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
  use data <- decode.then(decode.list(of: normalized_decoder()))
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

fn vector_add(a: Vector, b: Vector) -> Vector {
  Vector(a.x +. b.x, a.y +. b.y)
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

//TODO: if i want this to be tolerant i probably shouldnt do any normalized decoding at all
// just at compilation time if i see something that needs to be normalized i clamp it 0-1
pub fn normalized_vector_decoder() -> Decoder(Vector) {
  let full_vector_decoder = {
    use x <- decode.field(0, normalized_decoder())
    use y <- decode.field(1, normalized_decoder())
    decode.success(Vector(x:, y:))
  }

  let single_element_array_decoder = {
    use x <- decode.field(0, normalized_decoder())
    decode.success(Vector(x:, y: x))
  }

  let scalar_decoder = {
    use value <- decode.then(normalized_decoder())
    decode.success(Vector(x: value, y: value))
  }

  decode.one_of(full_vector_decoder, [
    single_element_array_decoder,
    scalar_decoder,
  ])
}

pub type BezierPath {
  //TODO: split vertices into a n > 1 list
  BezierPath(closed: Bool, first: Vertex, second: Vertex, rest: List(Vertex))
  // BezierPath(closed: Bool, vertices: List(Vertex))
}

// const zero_bezier_path = BezierPath(closed: False, vertices: [])
const zero_bezier_path = BezierPath(
  closed: False,
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

fn bezier_path_to_attribute(path: BezierPath) -> Attribute(Message) {
  let value =
    "M " <> vector_to_svg(path.first.position) <> curve(path.first, path.second)

  let #(last, value) =
    list.fold(path.rest, from: #(path.second, value), with: fn(acc, end) {
      let #(start, value) = acc

      let segment = curve(start, end)
      #(end, value <> segment)
    })

  let value = case path.closed {
    True -> value <> curve(last, path.first) <> " Z"
    False -> value
  }

  attribute.attribute("d", value)
  // case path.vertices {
  //   // a path needs at least 2 vertices
  //   [first, second, ..vertices] -> {
  //     let value = "M " <> vector_to_svg(first.position) <> curve(first, second)

  //     let #(last, value) =
  //       list.fold(vertices, from: #(second, value), with: fn(acc, end) {
  //         let #(start, value) = acc

  //         let segment = curve(start, end)
  //         #(end, value <> segment)
  //       })

  //     let value = case path.closed {
  //       True -> value <> curve(last, first) <> " Z"
  //       False -> value
  //     }

  //     attribute.attribute("d", value)
  //   }
  //   _ -> attribute.none()
  // }
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

pub fn bezier_path_decoder() -> Decoder(BezierPath) {
  use closed <- decode.optional_field("c", False, decode.bool)
  use positions <- decode.field("v", decode.list(of: vector_decoder()))
  use out_tangents <- decode.field("o", decode.list(of: vector_decoder()))
  use in_tangents <- decode.field("i", decode.list(of: vector_decoder()))

  let path = {
    use vertices <- result.try(
      build_vertices_loop(positions, out_tangents, in_tangents, []),
    )
    case vertices {
      [first, second, ..rest] -> Ok(BezierPath(closed:, first:, second:, rest:))
      _ -> Error(Nil)
    }
  }

  case path {
    Ok(path) -> decode.success(path)
    Error(Nil) -> decode.failure(zero_bezier_path, expected: "BezierPath")
  }
}

fn build_vertices_loop(
  positions: List(Vector),
  out_tangents: List(Vector),
  in_tangents: List(Vector),
  vertices: List(Vertex),
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
