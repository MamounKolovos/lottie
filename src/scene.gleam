import gleam/deque
import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/set.{type Set}
import lottie/internal/count.{type MutableCounter}
import lottie/internal/id
import lottie/internal/port_graph.{type PortGraph}
import lustre/element.{type Element}

// glossary:
// - source comp: the active composition that everything else (including all the precomps) is contained within
// - subcomp: the base sub-composition that all the precomps have as their reference

// premise: composition with a fill color override and 3 precomps each with a separate color (RGB)
// 	precomp 1 has a static red, precomp 2 has a static green, precomp 3 has its fill driven by a color utility

// notes:
// - the connection topology should be the same across all precomps, im pretty sure the only difference is the values
// that get passed into the precomp's external node
// - there needs to be a precomp drawable layer node thats present in the source comp
// - the key_to_value lookup table needs to contain a unique port -> value entry for each precomp
// 	so external ports must exist on a precomp basis not a comp basis
// - readonly properties that are the same on all precomps like width and height can exist on the composition asset rather than on every precomp

// source comp:
// - contains the subcomp asset and the 3 precomp drawable layers
// -

// precomp drawable layer:
// - contains a reference id to the subcomp asset
// - contains a set of override ports

// subcomp:
// - holds readonly properties width, height, fps
// - holds the current frame property 
// - holds the dependency graph which contains a "black box" external node
// 	- the external node will usually contain things like comp settings (frame, fps, etc) so that they can drive other nodes inside the comp
// 	- the external node can also contain pre comp overrides, but the overrides will be added at evaluation time for a pre comp, not baked in
// 	- TODO: see if it makes sense to change the graph topology at evaluation time, probably not right? 
// 		- I guess im not really changing the topology since all precomps are expected to expose the same port, only thing that changes is the value
// 		which should be loaded into the lookup table by the time the precomp is evaluated before we even go into the subcomp's dependency graph

// precomps 1 and 2:
// - precomp fill override port in source comp dependency graph
// - NO: external node with fill override port in subcomp dependency graph

// precomp 3:
// - connection from color utility fill property to precomp fill override port in source comp dependency graph
// - NO: external node with fill override port in subcomp dependency graph

// TODO: determine if overrides should go on comp asset or precomp
// 	 pretty sure they have to go on the precomps so the ports are unique, they cannot be shared since each precomp can independently connect

// -- NOTES --

// every composition needs to get its own dependency graph

// a composition is treated as just another layer node, but it's always the root of the graph

// a layer/node can only be evaluated after everything it depends on has been evaluated (kahns algo for topological sort)
// if shape A has a rotation input from shape B and a color input from shape C, B and C both need to evaluate fully before A can be

//NOTE: the scene should own the allocator not the compositions
pub type Scene {
  // Scene(allocator: id.Allocator, layers: List(Layer))
  Scene(dependency_graph: DependencyGraph, layers: Dict(Int, Layer))
}

//the property values here probably need to be flexible so that a float property can connect to a vector property or something
//an adapter abstraction could also be useful
pub type DependencyGraph {
  // DependencyGraph(graph: Dict(Int, Layer))
  DependencyGraph(
    graph: PortGraph(Slot),
    // for representing the actual port level states and their derivations
    // ports: Dict(PortKey, PropertyPort(Float)),
    // for representing the node level structure and the static fields
    // layers: Dict(Int, Layer),
  )
}

pub fn insert_dependency(
  graph: DependencyGraph,
  id: Int,
  layer: Layer,
) -> DependencyGraph {
  port_graph.insert(graph.graph, id)
  todo
}

// pub type PortKey {
//   PortKey(id: Int, slot: Slot)
// }

pub type Slot {
  Frame
  Position
  AnchorPoint
  Scale
  Opacity
  Rotation
  FillColorRed
  FillColorGreen
  FillColorBlue
  FillColorAlpha
  Width
  Height
}

const default_frame_value = 0.0

const default_rotation_value = 0.0

const default_position_value = Vector2(0.0, 0.0)

const default_anchor_point_value = Vector2(0.0, 0.0)

const default_scale_value = Vector2(1.0, 1.0)

const default_color_value = Color(r: 1.0, g: 0.0, b: 0.0, a: 1.0)

pub type Evaluation {
  Evaluation(
    values: Dict(port_graph.PortKey(Slot), PropertyValue),
    precomps: Dict(Int, Evaluation),
  )
}

pub type LayerTree {
  LayerTree(
    // id of the root node
    //NOTE: root not necessary since root is the comp anyways
    // root: Int,
    // id -> children ids
    children: Dict(Int, List(Int)),
    // id -> parent id
    parents: Dict(Int, Int),
  )
}

// pub type LayerNode {
//   LayerNode(id: Int, children: List(LayerNode))
// }

// pub type Object {
//   AssetObject
//   CompositionObject(Composition)
//   LayerObject(Layer)
// }

// every layer has an implicit transform matrix input and output
pub type Layer {
  DrawableLayer(Drawable)
  UtilityLayer(Utility)
}

pub type Drawable {
  CompositionDrawable(Composition)
  ShapeDrawable(Shape)
}

pub type Composition {
  Composition(
    frame: Property(Float),
    width: Property(Float),
    height: Property(Float),
    dependency_graph: DependencyGraph,
    layer_tree: LayerTree,
    // externals: Set(port_graph.PortKey(Slot)),
  )
}

pub type PreComposition {
  PreComposition(reference_id: Int)
}

pub type Shape {
  Rectangle(rotation: Property(Float), fill: ShapeFill)
}

pub type ShapeFill {
  ShapeFill(visible: Bool, color: ColorProperty)
}

pub type ColorProperty {
  ColorProperty(
    r: Property(Float),
    g: Property(Float),
    b: Property(Float),
    a: Property(Float),
  )
}

//NOTE: maybe the rule for utility nodes can be "they compute a value and they have 1 output which is the node itself"
pub type Utility {
  Fill(color: Property(Color))
  AnimationControl(amount: Float)
  //TODO: useful to map dependencies into appropriate ranges, like rotation to position or something
  Math(
    left: Property(Float),
    operator: Nil,
    right: Property(Float),
    result: Property(Float),
  )
}

//TODO: comp width, comp height, math utility result, string length, etc
// some properties can only drive, not be driven
pub type ReadonlyProperty

//TODO: might need to restructure this, not a guarantee that every property encapsulates only one port
//color properties for example have 4 ports, one for each RGBA component
pub type Property(value) {
  Property(key: port_graph.PortKey(Slot))
}

//TODO: each color component should be a port
pub type Color {
  Color(r: Float, g: Float, b: Float, a: Float)
}

const zero_color = Color(r: 0.0, g: 0.0, b: 0.0, a: 0.0)

pub type Vector2 {
  Vector2(x: Float, y: Float)
}

//NOTE: some properties are not keyframeable, like noise type or input shapes
// some properties are also not inputtable

pub type PropertyValue {
  ScalarValue(Float)
  VectorValue(Vector2)
  // ColorValue(Color)
}

// NOTE: there can be n adapters for an input value but only 1 for an output value
// like a float can technically map to both a vector and a color
// therefore it's the job of the output to provide the adapter for the input its trying to connect to
// like if rotation is trying to connect to position and fill color, it would provide scalar_to_vector and scalar_to_color respectively
// i believe it has to be like this since data flows downstream, but maybe it could be the other way around where each store an adapter respectively
// you also technically dont need to store it, could just call a top level function when needed i suppose, similar to the interpolator in `lottie.gleam`.
pub type Adapter(input, output) {
  Adapter(map: fn(input) -> output)
}

const float_to_vector = Adapter(map_float_to_vector)

fn map_float_to_vector(value: Float) -> Vector2 {
  Vector2(value, value)
}

//NOTE: from the duplicator shape layer we can deduce that a singular attribute in special circumstances can have N inputs

pub type Track(value) {
  Track(first: Keyframe(value), rest: List(Keyframe(value)))
}

pub type Keyframe(value)

pub fn main() -> Nil {
  let composition =
    Composition(
      frame: Property(port_graph.PortKey(id: 0, slot: Frame)),
      width: Property(port_graph.PortKey(id: 0, slot: Width)),
      height: Property(port_graph.PortKey(id: 0, slot: Height)),
      // width: 100.0,
      // height: 100.0,
      layer_tree: LayerTree(children: dict.new(), parents: dict.new()),
      dependency_graph: DependencyGraph(port_graph.new()),
    )

  let rectangle1 =
    Rectangle(
      rotation: Property(port_graph.PortKey(id: 1, slot: Rotation)),
      fill: ShapeFill(
        visible: True,
        color: ColorProperty(
          r: Property(port_graph.PortKey(id: 1, slot: FillColorRed)),
          g: Property(port_graph.PortKey(id: 1, slot: FillColorGreen)),
          b: Property(port_graph.PortKey(id: 1, slot: FillColorBlue)),
          a: Property(port_graph.PortKey(id: 1, slot: FillColorAlpha)),
        ),
      ),
    )

  let rectangle2 =
    Rectangle(
      rotation: Property(port_graph.PortKey(id: 2, slot: Rotation)),
      fill: ShapeFill(
        visible: True,
        color: ColorProperty(
          r: Property(port_graph.PortKey(id: 2, slot: FillColorRed)),
          g: Property(port_graph.PortKey(id: 2, slot: FillColorGreen)),
          b: Property(port_graph.PortKey(id: 2, slot: FillColorBlue)),
          a: Property(port_graph.PortKey(id: 2, slot: FillColorAlpha)),
        ),
      ),
    )

  let port_graph =
    port_graph.new()
    // i dont think i can insert the comp into the dep graph,
    // i need to insert the external node instead
    |> port_graph.insert(0)
    |> port_graph.insert(1)
    |> port_graph.connect(
      from: composition.frame.key,
      to: rectangle1.rotation.key,
    )
    |> port_graph.insert(2)
    |> port_graph.connect(
      from: rectangle1.rotation.key,
      to: rectangle2.rotation.key,
    )

  let layer_tree =
    LayerTree(
      children: dict.from_list([
        #(1, []),
        #(2, []),
      ]),
      parents: dict.new(),
    )

  let composition =
    Composition(
      ..composition,
      layer_tree:,
      dependency_graph: DependencyGraph(port_graph),
    )

  // this should probably be on the composition since it's tied to the comp layer tree
  // and dep graph
  //keep in mind that all static values should be here im just lazy atm
  // let key_to_value =
  //   dict.from_list([
  //     #(composition.frame.key, ScalarValue(0.0)),
  //     #(rectangle1.fill.color.r.key, ScalarValue(0.0)),
  //     #(rectangle1.fill.color.g.key, ScalarValue(0.0)),
  //     #(rectangle1.fill.color.b.key, ScalarValue(0.0)),
  //     #(rectangle1.fill.color.a.key, ScalarValue(0.0)),
  //   ])

  let static_values =
    dict.from_list([
      #(composition.frame.key, ScalarValue(10.0)),
      #(composition.width.key, ScalarValue(200.0)),
      #(composition.height.key, ScalarValue(200.0)),
      // #(rectangle1.fill.color.r.key, ScalarValue(0.0)),
    // #(rectangle1.fill.color.g.key, ScalarValue(0.0)),
    // #(rectangle1.fill.color.b.key, ScalarValue(0.0)),
    // #(rectangle1.fill.color.a.key, ScalarValue(0.0)),
    ])

  let nodes =
    dict.from_list([
      #(
        0,
        ExternalNode(
          externals: set.from_list([
            composition.frame.key,
            // composition.width.key,
          // composition.height.key,
          ]),
        ),
      ),
      #(1, LayerNode(DrawableLayer(ShapeDrawable(rectangle1)))),
      #(2, LayerNode(DrawableLayer(ShapeDrawable(rectangle2)))),
    ])
  //TODO: layers should be part of the composition, since it goes side by side with the layer tree
  // let layers =
  //   dict.from_list([
  //     // need to remove and rethink this, composition cannot exist in its own layer tree but it CAN participate in its own dependency graph
  //     #(0, DrawableLayer(CompositionDrawable(composition))),
  //     #(1, DrawableLayer(ShapeDrawable(rectangle1))),
  //     #(2, DrawableLayer(ShapeDrawable(rectangle2))),
  //   ])

  evaluate(composition, nodes, static_values) |> echo
  Nil
}

pub type DependencyNode {
  ExternalNode(externals: Set(port_graph.PortKey(Slot)))
  LayerNode(Layer)
}

// fill layer color outputs to shape 1 and shape 2 color input
// shape 1 rotation outputs to shape 2 rotation input
// shape 2 cannot be evaluated until both fill and shape 1 are evaluated

//NOTE: evaluation is *pull-based*, a driven node resolves its value by doing a lookup on the parent's value in the key-value mapping

//IMPORTANT NOTE: driver is just a static property that happens to have inputs its outputting to
// need to look and see if theres a tangible benefit to have a separate static dictionary

//TODO: this should take in a composition not a dependency graph
fn evaluate(
  composition: Composition,
  // layers: Dict(Int, Layer),
  nodes: Dict(Int, DependencyNode),
  key_to_value: Dict(port_graph.PortKey(Slot), PropertyValue),
) -> Dict(port_graph.PortKey(Slot), PropertyValue) {
  let assert Ok(ordering) = port_graph.sort(composition.dependency_graph.graph)

  let key_to_value =
    list.fold(ordering, from: key_to_value, with: fn(key_to_value, id) {
      case dict.get(nodes, id) {
        Ok(node) ->
          case node {
            ExternalNode(externals: _) -> {
              key_to_value
            }
            LayerNode(layer) ->
              case layer {
                DrawableLayer(layer) ->
                  case layer {
                    CompositionDrawable(Composition(
                      frame:,
                      width:,
                      height:,
                      dependency_graph:,
                      layer_tree:,
                    )) -> {
                      let #(frame, key_to_value) =
                        resolve_scalar(
                          composition.dependency_graph,
                          key_to_value,
                          frame,
                          default_frame_value,
                        )
                      key_to_value
                    }
                    ShapeDrawable(shape) ->
                      case shape {
                        Rectangle(rotation:, fill:) -> {
                          let #(rotation, key_to_value) =
                            resolve_scalar(
                              composition.dependency_graph,
                              key_to_value,
                              rotation,
                              default_rotation_value,
                            )
                          key_to_value
                        }
                      }
                  }
                UtilityLayer(_) -> todo
              }
          }

        Error(Nil) -> key_to_value
      }
    })

  key_to_value
}

fn resolve_externals(
  dependency_graph: DependencyGraph,
  key_to_value: Dict(port_graph.PortKey(Slot), PropertyValue),
  externals: Set(port_graph.PortKey(Slot)),
) -> Dict(port_graph.PortKey(Slot), PropertyValue) {
  todo
}

fn resolve_scalar(
  dependency_graph: DependencyGraph,
  key_to_value: Dict(port_graph.PortKey(Slot), PropertyValue),
  property: Property(Float),
  default_value: Float,
) -> #(Float, Dict(port_graph.PortKey(Slot), PropertyValue)) {
  let key = case dict.get(dependency_graph.graph.inputs, property.key) {
    Ok(source) -> source
    Error(Nil) -> property.key
  }

  let value = case dict.get(key_to_value, key) {
    Ok(ScalarValue(value)) -> value
    _ -> default_value
  }

  // unconditionally insert, doesn't really matter even if it's a static/driver property
  #(value, dict.insert(key_to_value, property.key, ScalarValue(value)))
}

fn get_color(
  key_to_value: Dict(port_graph.PortKey(Slot), PropertyValue),
  property: ColorProperty,
) -> Result(Color, Nil) {
  todo
  // case dict.get(key_to_value, property.key) {
  //   Ok(value) ->
  //     case value {
  //       ColorValue(value) -> Ok(value)
  //       _ -> Error(Nil)
  //     }
  //   Error(Nil) -> Error(Nil)
  // }
}
