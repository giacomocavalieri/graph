import gleam/dict.{type Dict}
import gleam/list
import gleam/queue.{type Queue}
import gleam/result

type Node =
  Int

type IntDict(a) =
  Dict(Int, a)

pub opaque type Graph(value, label) {
  Graph(IntDict(Context(value, label)))
}

type Context(value, label) {
  Context(
    incoming: IntDict(List(label)),
    value: value,
    outgoing: IntDict(List(label)),
  )
}

pub type View(value, label) {
  View(
    incoming: IntDict(List(label)),
    value: value,
    node: Int,
    outgoing: IntDict(List(label)),
    rest: Graph(value, label),
  )
}

// --- CREATING A GRAPH --------------------------------------------------------

pub fn new() -> Graph(value, label) {
  Graph(dict.new())
}

// --- MAPPING A GRAPH ---------------------------------------------------------

pub fn map(
  in graph: Graph(value, label),
  values_with values_map: fn(value) -> new_value,
  labels_with labels_map: fn(label) -> new_label,
) -> Graph(new_value, new_label) {
  let Graph(graph) = graph
  let map_all_labels = fn(_, labels) { list.map(labels, labels_map) }

  Graph({
    use _, context <- dict.map_values(graph)
    let Context(incoming: incoming, value: value, outgoing: outgoing) = context
    let incoming = dict.map_values(incoming, map_all_labels)
    let outgoing = dict.map_values(outgoing, map_all_labels)
    let value = values_map(value)
    Context(incoming: incoming, value: value, outgoing: outgoing)
  })
}

pub fn map_values(
  in graph: Graph(value, label),
  with fun: fn(value) -> new_value,
) -> Graph(new_value, label) {
  let Graph(graph) = graph

  Graph({
    use _, context <- dict.map_values(graph)
    let Context(incoming: incoming, value: value, outgoing: outgoing) = context
    Context(incoming: incoming, value: fun(value), outgoing: outgoing)
  })
}

pub fn map_labels(
  in graph: Graph(value, label),
  with fun: fn(label) -> new_label,
) -> Graph(value, new_label) {
  let Graph(graph) = graph
  let map_all_labels = fn(_, labels) { list.map(labels, fun) }

  Graph({
    use _, context <- dict.map_values(graph)
    let Context(incoming: incoming, value: value, outgoing: outgoing) = context
    let incoming = dict.map_values(incoming, map_all_labels)
    let outgoing = dict.map_values(outgoing, map_all_labels)
    Context(incoming: incoming, value: value, outgoing: outgoing)
  })
}

// --- ADDING NODES ------------------------------------------------------------

// THIS REPLACES ANY EXISTING NODE!!!!
pub fn insert_node(
  in graph: Graph(value, label),
  node node: Int,
  value value: value,
) -> Graph(value, label) {
  let Graph(graph) = graph

  dict.insert(graph, node, Context(dict.new(), value, dict.new()))
  |> Graph
}

pub fn insert_edge(
  in graph: Graph(value, label),
  from source: Int,
  to destination: Int,
  labelled label: label,
) -> Graph(value, label) {
  let Graph(graph) = graph

  dict_adjust(graph, source, fn(context) {
    let Context(outgoing: outgoing, ..) = context
    let outgoing = dict_add_list_value(outgoing, destination, label)
    Context(..context, outgoing: outgoing)
  })
  |> dict_adjust(destination, fn(context) {
    let Context(incoming: incoming, ..) = context
    let incoming = dict_add_list_value(incoming, source, label)
    Context(..context, incoming: incoming)
  })
  |> Graph
}

// --- QUERYING A GRAPH --------------------------------------------------------

pub fn is_empty(graph: Graph(value, label)) -> Bool {
  let Graph(graph) = graph

  graph == dict.new()
}

pub fn count_nodes(graph: Graph(value, label)) -> Int {
  let Graph(graph) = graph

  dict.size(graph)
}

pub fn view(
  in graph: Graph(value, label),
  node node: Node,
) -> Result(View(value, label), Nil) {
  let Graph(graph) = graph

  use context <- result.try(dict.get(graph, node))
  let Context(incoming: incoming, value: value, outgoing: outgoing) = context
  let incoming = dict.delete(incoming, node)
  let outgoing = dict.delete(outgoing, node)
  let rest =
    dict.delete(graph, node)
    |> remove_incoming_occurrences(of: node, from: outgoing)
    |> remove_outgoing_occurrences(of: node, from: incoming)
    |> Graph

  Ok(View(
    incoming: incoming,
    node: node,
    value: value,
    outgoing: outgoing,
    rest: rest,
  ))
}

fn remove_incoming_occurrences(
  in graph: IntDict(Context(value, label)),
  of node: Int,
  from nodes: IntDict(a),
) -> IntDict(Context(value, label)) {
  use context, _ <- dict_map_shared_keys(graph, with: nodes)
  let Context(incoming: incoming, ..) = context
  Context(..context, incoming: dict.delete(incoming, node))
}

fn remove_outgoing_occurrences(
  in graph: IntDict(Context(value, label)),
  of node: Int,
  from nodes: IntDict(a),
) -> IntDict(Context(value, label)) {
  use context, _ <- dict_map_shared_keys(graph, with: nodes)
  let Context(outgoing: outgoing, ..) = context
  Context(..context, outgoing: dict.delete(outgoing, node))
}

// --- SEARCHING A GRAPH -------------------------------------------------------

pub fn bfs(graph: Graph(value, label), node: Node) -> List(Node) {
  do_bfs(graph, queue.from_list([node]), [])
}

fn do_bfs(
  graph: Graph(value, label),
  queue: Queue(Node),
  acc: List(Node),
) -> List(Node) {
  case is_empty(graph), queue.pop_front(queue) {
    True, _ | _, Error(_) -> list.reverse(acc)
    _, Ok(#(node_to_explore, queue)) ->
      case view(graph, node_to_explore) {
        Error(_) -> do_bfs(graph, queue, acc)
        Ok(View(node: node, outgoing: outgoing, rest: rest, ..)) -> {
          let successors = dict.keys(outgoing)
          let queue = push_back_all(queue, successors)
          do_bfs(rest, queue, [node, ..acc])
        }
      }
  }
}

fn push_back_all(queue: Queue(a), values: List(a)) -> Queue(a) {
  use queue, value <- list.fold(over: values, from: queue)
  queue.push_back(queue, value)
}

// --- DICT UTILITY FUNCTIONS --------------------------------------------------

fn dict_map_shared_keys(
  in one: Dict(k, a),
  with other: Dict(k, b),
  using fun: fn(a, b) -> a,
) -> Dict(k, a) {
  use one, key, other_value <- dict.fold(over: other, from: one)
  case dict.get(one, key) {
    Ok(one_value) -> dict.insert(one, key, fun(one_value, other_value))
    Error(_) -> one
  }
}

fn dict_adjust(
  in dict: Dict(k, a),
  at key: k,
  with fun: fn(a) -> a,
) -> Dict(k, a) {
  case dict.get(dict, key) {
    Ok(value) -> dict.insert(dict, key, fun(value))
    Error(_) -> dict
  }
}

fn dict_add_list_value(
  in dict: Dict(k, List(a)),
  at key: k,
  this value: a,
) -> Dict(k, List(a)) {
  case dict.get(dict, key) {
    Ok(values) -> dict.insert(dict, key, [value, ..values])
    Error(_) -> dict.insert(dict, key, [value])
  }
}
