import gleam/bool
import gleam/deque.{type Deque}
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/set.{type Set}
import lottie/internal/count.{type MutableCounter}

//TODO: phantom types for topological sort
pub type Sorted

//TODO: phantom types for topological sort
pub type Unsorted

pub type PortGraph(slot) {
  PortGraph(
    nodes: Set(Int),
    // input to output
    inputs: Dict(PortKey(slot), PortKey(slot)),
    // output to set of inputs
    outputs: Dict(PortKey(slot), Set(PortKey(slot))),
    // counter: MutableCounter,
  )
}

//TODO: phantom types to force caller order on connect()
pub type Input

pub type Output

//TODO: just make slot an int, no reason for a generic
pub type PortKey(slot) {
  PortKey(id: Int, slot: slot)
}

pub fn new() -> PortGraph(slot) {
  PortGraph(nodes: set.new(), inputs: dict.new(), outputs: dict.new())
}

pub fn insert(graph: PortGraph(slot), id: Int) -> PortGraph(slot) {
  PortGraph(..graph, nodes: set.insert(graph.nodes, id))
}

//TODO: handle connection cycles
// Example: 1A -> 2Y, 2Y -> 3Z, 3Z -> 1A
pub fn connect(
  graph: PortGraph(slot),
  from output: PortKey(slot),
  to input: PortKey(slot),
) -> PortGraph(slot) {
  // cannot connect to a port on the same node
  use <- bool.guard(output.id == input.id, return: graph)
  // output's node does not exist in the graph
  use <- bool.guard(!set.contains(graph.nodes, output.id), return: graph)
  // input's node does not exist in the graph
  use <- bool.guard(!set.contains(graph.nodes, input.id), return: graph)

  // connection exists from output 1A to 2Y
  // new connection tries to go from 1B to 2Y
  // need to remove 2Y from 1A's output set and insert into 1B's output set

  //connection already exists, need to remove the old one so i can add the new one
  case dict.get(graph.inputs, input) {
    Ok(old_output) if old_output != output -> {
      let inputs = dict.insert(graph.inputs, input, output)

      let outputs = case dict.get(graph.outputs, old_output) {
        Ok(input_ports) -> {
          let input_ports = set.delete(input_ports, input)
          case set.is_empty(input_ports) {
            True -> dict.delete(graph.outputs, old_output)
            False -> dict.insert(graph.outputs, old_output, input_ports)
          }
        }
        Error(Nil) -> graph.outputs
      }

      let outputs =
        dict.upsert(outputs, output, fn(port_inputs) {
          case port_inputs {
            option.Some(port_inputs) -> set.insert(port_inputs, input)
            option.None -> set.new() |> set.insert(input)
          }
        })

      PortGraph(..graph, inputs:, outputs:)
    }
    _ -> {
      let inputs = dict.insert(graph.inputs, input, output)
      let outputs =
        dict.upsert(graph.outputs, output, fn(port_inputs) {
          case port_inputs {
            option.Some(port_inputs) -> set.insert(port_inputs, input)
            option.None -> set.new() |> set.insert(input)
          }
        })
      PortGraph(..graph, inputs:, outputs:)
    }
  }
}

pub fn disconnect(
  graph: PortGraph(slot),
  input: PortKey(slot),
) -> PortGraph(slot) {
  todo
}

// pub fn connect(
//   graph: PortGraph(slot, value),
//   input: PortKey(slot),
//   output: PortKey(slot),
// ) -> PortGraph(slot, value) {
//   todo
// }

pub fn sort(graph: PortGraph(slot)) -> Result(List(Int), Nil) {
  let #(predecessors, successors) =
    dict.fold(
      graph.inputs,
      from: #(dict.new(), dict.new()),
      with: fn(acc, input, output) {
        let #(predecessors, successors) = acc

        let predecessors =
          dict.upsert(predecessors, input.id, fn(existing) {
            existing |> option.unwrap(set.new()) |> set.insert(output.id)
          })

        let successors =
          dict.upsert(successors, output.id, fn(existing) {
            existing |> option.unwrap(set.new()) |> set.insert(input.id)
          })

        #(predecessors, successors)
      },
    )

  let in_degrees =
    set.fold(graph.nodes, from: dict.new(), with: fn(acc, id) {
      let in_degree = case dict.get(predecessors, id) {
        Ok(sources) -> set.size(sources)
        Error(Nil) -> 0
      }
      dict.insert(acc, id, in_degree)
    })

  let queue =
    dict.fold(in_degrees, from: deque.new(), with: fn(acc, id, in_degree) {
      case in_degree == 0 {
        True -> deque.push_back(acc, id)
        False -> acc
      }
    })

  topological_sort_loop(queue, in_degrees, successors, [])
}

fn topological_sort_loop(
  queue: deque.Deque(Int),
  in_degrees: Dict(Int, Int),
  successors: Dict(Int, Set(Int)),
  ordering: List(Int),
) -> Result(List(Int), Nil) {
  case deque.pop_front(queue) {
    Ok(#(id, queue)) -> {
      let outgoing = dict.get(successors, id) |> result.unwrap(set.new())

      let #(queue, in_degrees) =
        set.fold(outgoing, #(queue, in_degrees), fn(acc, target_id) {
          let #(queue, in_degrees) = acc
          case dict.get(in_degrees, target_id) {
            Ok(count) -> {
              let remaining = count - 1
              let in_degrees = dict.insert(in_degrees, target_id, remaining)
              case remaining {
                0 -> #(deque.push_back(queue, target_id), in_degrees)
                _ -> #(queue, in_degrees)
              }
            }
            Error(_) -> acc
          }
        })

      topological_sort_loop(queue, in_degrees, successors, [id, ..ordering])
    }
    Error(_) -> {
      case list.length(ordering) == dict.size(in_degrees) {
        True -> Ok(list.reverse(ordering))
        False -> Error(Nil)
      }
    }
  }
}

// -- testing/development --

pub fn main() -> Nil {
  let graph = new()

  let graph =
    graph
    |> insert(0)
    |> insert(1)
    |> insert(2)
    |> connect(
      from: PortKey(id: 0, slot: Rotation),
      to: PortKey(id: 2, slot: Opacity),
    )
    |> connect(
      from: PortKey(id: 1, slot: FillColor),
      to: PortKey(id: 2, slot: FillColor),
    )
    |> insert(3)
    |> connect(
      from: PortKey(id: 2, slot: FillColor),
      to: PortKey(id: 3, slot: FillColor),
    )

  // echo graph as "before"
  echo sort(graph) as "after"

  // TODO: i dont think a proper dependency graph abstraction can be made here, since id to value is something that needs to be accessible to the layer tree as well

  // also important to note that right now layers are required to have an id in the port graph which obviously shouldnt be a requirement since not every layer/node
  // will be in the graph, only driver nodes or driven nodes

  // let #(id1, graph) = insert(graph)
  // let fill =
  //   FillUtility(color: Port(
  //     key: PortKey(id: id1, slot: FillColor),
  //     value: Driver(ColorValue(zero_color)),
  //   ))

  // let #(id2, graph) = insert(graph)
  // let rectangle = Rectangle(
  //   rotation
  // )

  // let graph =
  //   connect(
  //     graph,
  //     from: PortKey(id: id1, slot: Rotation),
  //     to: PortKey(id: id2, slot: FillColor),
  //   )

  // let x =
  //   set.from_list([
  //     PortKey(id: 0, slot: Rotation),
  //     PortKey(id: 1, slot: FillColor),
  //   ])
  // let fill = FillUtility(color: FillColor)
  Nil
}

type Layer {
  Rectangle(
    rotation: Port(Slot, Float),
    // position: Port(Slot, Vector2),
    color: Port(Slot, Color),
  )
  FillUtility(color: Port(Slot, Color))
  // FillUtility(color: Slot)
}

pub type Color {
  Color(r: Float, g: Float, b: Float, a: Float)
}

const zero_color = Color(r: 0.0, g: 0.0, b: 0.0, a: 0.0)

pub type Vector2 {
  Vector2(x: Float, y: Float)
}

const zero_vector = Vector2(0.0, 0.0)

type Slot {
  Position
  Rotation
  Opacity
  FillColor
}

pub type Port(slot, value) {
  Port(key: PortKey(slot), value: PortValue(value))
}

// inevitably i will need a node id to value dictionary so im not sure if making this generic works
// i might just need a closed set over any possible
pub type PortValue(value) {
  Driver(DependencyValue)
  Driven
}

pub type DependencyValue {
  FloatValue(Float)
  VectorValue(Vector2)
  ColorValue(Color)
}
