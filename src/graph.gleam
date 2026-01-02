////
//// Here's a handy index you can use to browse through the various graph
//// functions.
////
//// | operation kind | functions |
//// |---|---|
//// | creating graphs | [`new`](#new) |
//// | turning graphs into lists | [`nodes`](#nodes) |
//// | querying a graph | [`size`](#size), [`has_node`](#has_node), [`has_edge`](#has_edge), [`get_context`](#get_context), [`match`](#match), [`match_any`](#match_any) |
//// | adding/removing elements from a graph | [`insert_node`](#insert_node), [`insert_directed_edge`](#insert_directed_edge), [`insert_undirected_edge`](#insert_undirected_edge), [`remove_node`](#remove_node), [`remove_directed_edge`](#remove_directed_edge), [`remove_undirected_edge`](#remove_undirected_edge) |
//// | transforming graphs | [`reverse_edges`](#reverse_edges), [`to_directed`](#to_directed) |
////

import gleam/dict.{type Dict}
import gleam/result

// --- THE GRAPH TYPE ----------------------------------------------------------

/// The direction of a directed graph.
///
pub type Directed

/// The direction of an undirected graph.
///
pub type Undirected

/// A directed or undirected graph. A graph is made up of nodes and edges
/// connecting them: each node holds a `value` and each edge has a `label`.
///
/// The graph also carries along its `direction` (either `Directed` or
/// `Undirected`) in its type so that it's impossible to mix up `Directed` and
/// `Undirected` graphs inadvertently.
///
pub opaque type Graph(direction, value, label) {
  Graph(Dict(Int, Context(value, label)))
}

/// A node making up a graph. Every node is identified by a number and can hold
/// an arbitrary value.
///
pub type Node(value) {
  Node(id: Int, value: value)
}

/// The context associated with a node in a graph: it contains the node itself
/// and all the incoming and outgoing edges. Edges are stored in a dict going
/// from neighbour's id to the edge label.
///
pub type Context(value, label) {
  Context(
    incoming: Dict(Int, label),
    node: Node(value),
    outgoing: Dict(Int, label),
  )
}

// --- CREATING GRAPHS ---------------------------------------------------------

/// Creates a new empty graph.
///
pub fn new() -> Graph(direction, value, label) {
  Graph(dict.new())
}

// --- TURNING GRAPHS INTO LISTS -----------------------------------------------

/// Returns a list of all the nodes contained in the graph.
///
/// ## Examples
///
/// ```gleam
/// assert [] == graph.new() |> graph.nodes
/// assert [graph.Node(1, "")]
///   == graph.new()
///   |> graph.insert_node(graph.Node(1, "a node"))
///   |> graph.nodes
/// ```
///
pub fn nodes(graph: Graph(direction, value, label)) -> List(Node(value)) {
  let Graph(graph) = graph
  use acc, _node_id, Context(node: node, ..) <- dict.fold(over: graph, from: [])
  [node, ..acc]
}

// --- QUERYING A GRAPH --------------------------------------------------------

/// Returns the number of nodes of the graph.
///
/// ## Examples
///
/// ```gleam
/// assert 0 == graph.new() |> graph.size
/// assert 1
///   == graph.new()
///   |> graph.insert_node(graph.Node(1, "a node"))
///   |> graph.size
/// ```
///
pub fn size(graph: Graph(direction, value, label)) -> Int {
  let Graph(graph) = graph
  dict.size(graph)
}

/// Returns `True` if the graph contains a node with the given id.
///
/// ## Examples
///
/// ```gleam
/// let graph =
///   graph.new()
///   |> graph.insert_node(graph.Node(1, "a node"))
///
/// assert graph.has_node(graph, 1)
/// assert !graph.has_node(graph, 2)
/// ```
///
pub fn has_node(graph: Graph(direction, value, label), node_id: Int) -> Bool {
  let Graph(graph) = graph
  dict.has_key(graph, node_id)
}

/// Returns `True` if the graph has an edge connecting the two nodes with the
/// given ids.
///
/// ## Examples
///
/// ```gleam
/// let graph =
///   graph.new()
///   |> graph.insert_node(graph.Node(1, "a node"))
///   |> graph.insert_node(graph.Node(2, "another node"))
///   |> graph.insert_directed_edge("label", from: 1, to: 2)
///
/// assert graph.has_edge(graph, from: 1, to: 2)
/// assert !graph.has_edge(graph, from: 2, to: 1)
/// ```
///
pub fn has_edge(
  graph: Graph(direction, value, label),
  from source: Int,
  to destination: Int,
) -> Bool {
  case get_context(graph, source) {
    Ok(Context(outgoing: outgoing, ..)) -> dict.has_key(outgoing, destination)
    Error(_) -> False
  }
}

/// Returns the context associated with the node with the given id, if present.
/// Otherwise returns `Error(Nil)`.
///
/// ## Examples
///
/// ```gleam
/// assert Error(Nil) == graph.new() |> graph.get_context(of: 1)
/// let assert Ok(graph.Context(node: Node(1, "a node"), ..)) =
///   graph.new()
///   |> graph.insert_node(graph.Node(1, "a node"))
///   |> graph.get_context(of: 1)
/// ```
///
pub fn get_context(
  graph: Graph(direction, value, label),
  of node: Int,
) -> Result(Context(value, label), Nil) {
  let Graph(graph) = graph
  dict.get(graph, node)
}

/// If the graph contains a node with the given id, returns a tuple containing
/// the context of that node (with all edges looping back to itself removed) and
/// the "remaining" graph: that is, the original graph where that node has been
/// removed.
///
pub fn match(
  graph: Graph(direction, value, label),
  node_id: Int,
) -> Result(#(Context(value, label), Graph(direction, value, label)), Nil) {
  use Context(incoming, node, outgoing) <- result.try(get_context(
    graph,
    node_id,
  ))
  let rest = remove_node(graph, node_id)
  let new_incoming = dict.delete(incoming, node_id)
  let new_outgoing = dict.delete(outgoing, node_id)
  Ok(#(Context(new_incoming, node, new_outgoing), rest))
}

/// If the graph contains any node, returns a tuple containing a node of the
/// graph (with all edges looping back to itself removed) and the "remaining"
/// graph: that is, the original graph where that node has been removed.
///
pub fn match_any(
  graph: Graph(direction, value, label),
) -> Result(#(Context(value, label), Graph(direction, value, label)), Nil) {
  let Graph(dict) = graph
  case dict.keys(dict) {
    [] -> Error(Nil)
    [first, ..] -> match(graph, first)
  }
}

// --- ADDING/REMOVING ELEMENTS FROM A GRAPH -----------------------------------

/// Adds a node to the given graph.
/// If the graph already contains a node with the same id, that will be replaced
/// by the new one.
/// The newly added node won't be connected to any existing node.
///
pub fn insert_node(
  graph: Graph(direction, value, label),
  node: Node(value),
) -> Graph(direction, value, label) {
  let Graph(graph) = graph
  let empty_context = Context(dict.new(), node, dict.new())
  let new_graph = dict.insert(graph, node.id, empty_context)
  Graph(new_graph)
}

/// Adds an edge connecting two nodes in a directed graph.
///
pub fn insert_directed_edge(
  graph: Graph(Directed, value, label),
  labelled label: label,
  from source: Int,
  to destination: Int,
) -> Graph(Directed, value, label) {
  graph
  |> update_context(of: source, with: add_outgoing_edge(_, destination, label))
  |> update_context(of: destination, with: add_incoming_edge(_, source, label))
}

/// Adds an edge connecting two nodes in an undirected graph.
///
pub fn insert_undirected_edge(
  graph: Graph(Undirected, value, label),
  labelled label: label,
  between one: Int,
  and other: Int,
) -> Graph(Undirected, value, label) {
  graph
  |> update_context(of: one, with: fn(context) {
    add_outgoing_edge(context, other, label)
    |> add_incoming_edge(other, label)
  })
  |> update_context(of: other, with: fn(context) {
    add_outgoing_edge(context, one, label)
    |> add_incoming_edge(one, label)
  })
}

fn update_context(
  in graph: Graph(direction, value, label),
  of node: Int,
  with fun: fn(Context(value, label)) -> Context(value, label),
) -> Graph(direction, value, label) {
  let Graph(graph) = graph
  case dict.get(graph, node) {
    Ok(context) -> Graph(dict.insert(graph, node, fun(context)))
    Error(_) -> Graph(graph)
  }
}

fn add_outgoing_edge(
  context: Context(value, label),
  to node: Int,
  labelled label: label,
) -> Context(value, label) {
  let Context(outgoing: outgoing, ..) = context
  Context(..context, outgoing: dict.insert(outgoing, node, label))
}

fn remove_outgoing_edge(
  context: Context(value, label),
  to node: Int,
) -> Context(value, label) {
  let Context(outgoing: outgoing, ..) = context
  Context(..context, outgoing: dict.delete(outgoing, node))
}

fn add_incoming_edge(
  context: Context(value, label),
  from node: Int,
  labelled label: label,
) -> Context(value, label) {
  let Context(incoming: incoming, ..) = context
  Context(..context, incoming: dict.insert(incoming, node, label))
}

fn remove_incoming_edge(
  context: Context(value, label),
  from node: Int,
) -> Context(value, label) {
  let Context(incoming: incoming, ..) = context
  Context(..context, incoming: dict.delete(incoming, node))
}

/// Removes a node with the given id from the graph. If there's no node with the
/// given id it does nothing.
///
pub fn remove_node(
  graph: Graph(direction, value, label),
  node_id: Int,
) -> Graph(direction, value, label) {
  case graph, get_context(graph, node_id) {
    _, Error(_) -> graph
    Graph(graph), Ok(Context(incoming, _, outgoing)) ->
      dict.delete(graph, node_id)
      |> remove_incoming_occurrences(of: node_id, from: outgoing)
      |> remove_outgoing_occurrences(of: node_id, from: incoming)
      |> Graph
  }
}

fn remove_incoming_occurrences(
  in graph: Dict(Int, Context(value, label)),
  of node: Int,
  from nodes: Dict(Int, a),
) -> Dict(Int, Context(value, label)) {
  use context, _ <- dict_map_shared_keys(graph, with: nodes)
  let Context(incoming: incoming, ..) = context
  Context(..context, incoming: dict.delete(incoming, node))
}

fn remove_outgoing_occurrences(
  in graph: Dict(Int, Context(value, label)),
  of node: Int,
  from nodes: Dict(Int, a),
) -> Dict(Int, Context(value, label)) {
  use context, _ <- dict_map_shared_keys(graph, with: nodes)
  let Context(outgoing: outgoing, ..) = context
  Context(..context, outgoing: dict.delete(outgoing, node))
}

/// Removes a directed edge connecting two nodes from a graph.
///
pub fn remove_directed_edge(
  graph: Graph(Directed, value, label),
  from source: Int,
  to destination: Int,
) -> Graph(Directed, value, label) {
  graph
  |> update_context(of: source, with: remove_outgoing_edge(_, to: destination))
  |> update_context(of: destination, with: remove_incoming_edge(_, from: source))
}

/// Removes an undirected edge connecting two nodes from a graph.
///
pub fn remove_undirected_edge(
  graph: Graph(Undirected, value, label),
  between one: Int,
  and other: Int,
) -> Graph(Undirected, value, label) {
  graph
  |> update_context(of: one, with: fn(context) {
    remove_outgoing_edge(context, to: other)
    |> remove_incoming_edge(from: other)
  })
  |> update_context(of: other, with: fn(context) {
    remove_outgoing_edge(context, to: one)
    |> remove_incoming_edge(from: one)
  })
}

// --- TRANSFORMING GRAPHS -----------------------------------------------------

// /// Reduces the given graph into a single value by applying function to all its
// /// contexts, one after the other.
// ///
// /// > 🚨 Graph's contexts are not sorted in any way so your folding function
// /// > should never rely on any accidental order the contexts might have.
// ///
// /// ## Examples
// ///
// /// ```gleam
// /// // The size function could be implemented using a fold.
// /// // The real implementation is more efficient because it doesn't have to
// /// // traverse all contexts!
// /// pub fn size(graph) {
// ///   fold(
// ///     over: graph,
// ///     from: 0,
// ///     with: fn(size, _context) { size + 1 },
// ///   )
// /// }
// /// ```
// ///
// pub fn fold(
//   over graph: Graph(direction, value, label),
//   from initial: b,
//   with fun: fn(b, Context(value, label)) -> b,
// ) -> b {
//   let Graph(graph) = graph
//   use acc, _node_id, context <- dict.fold(over: graph, from: initial)
//   fun(acc, context)
// }

// /// Transform the contexts associated with each node.
// ///
// /// > This function can add and remove arbitrary edges from the graph by
// /// > updating the `incoming` and `outgoing` edges of a context.
// /// > So we can't assume the final graph will still be `Undirected`, that's why
// /// > it is always treated as a `Directed` one.
// ///
// /// ## Examples
// ///
// /// ```gleam
// /// // The reverse function can be implemented with `map_contexts`
// /// pub fn reverse(graph) {
// ///   map_contexts(in: graph, with: fn(context) {
// ///     Context(
// ///       ..context,
// ///       incoming: context.outgoing,
// ///       outgoing: context.incoming,
// ///     )
// ///   })
// /// }
// /// ```
// ///
// pub fn map_contexts(
//   in graph: Graph(direction, value, label),
//   with fun: fn(Context(value, label)) -> Context(value, label),
// ) -> Graph(Directed, value, label) {
//   use acc, context <- fold(over: graph, from: new())
//   insert_context(acc, fun(context))
// }

// fn insert_context(
//   graph: Graph(direction, value, label),
//   context: Context(value, label),
// ) -> Graph(Directed, value, label) {
//   let Graph(graph) = graph
//   let new_graph = dict.insert(graph, context.node.id, context)
//   Graph(new_graph)
// }

// /// Transforms the values of all the graph's nodes using the given function.
// ///
// /// ## Examples
// ///
// /// ```gleam
// /// new()
// /// |> insert_node(Node(1, "a node"))
// /// |> map_nodes(fn(value) { value <> "!" })
// /// |> nodes
// /// // -> [Node(1, "my node!")]
// /// ```
// ///
// pub fn map_values(
//   in graph: Graph(direction, value, label),
//   with fun: fn(value) -> new_value,
// ) -> Graph(direction, new_value, label) {
//   let Graph(graph) = graph
//   // Since this function doesn't change the graph's topology I'm not
//   // implementing it with a `graph.fold` or a `graph.map_contexts`, it would
//   // increase code reuse but would rebuild a new graph each time by adding
//   // each context one by one.
//   Graph({
//     use _node_id, context <- dict.map_values(graph)
//     let Context(incoming, Node(id, value), outgoing) = context
//     Context(incoming, Node(id, fun(value)), outgoing)
//   })
// }

// /// Transforms the labels of all the graph's edges using the given function.
// ///
// /// ## Examples
// ///
// /// ```
// /// new()
// /// |> insert_node(Node(1, "a node"))
// /// |> insert_undirected_edge(UndirectedEdge(1, 1, "label"))
// /// |> map_labels(fn(label) { label <> "!" })
// /// |> labels
// /// // -> ["label!"]
// /// ```
// ///
// pub fn map_labels(
//   in graph: Graph(direction, value, label),
//   with fun: fn(label) -> new_label,
// ) -> Graph(direction, value, new_label) {
//   // Since this function doesn't change the graph's topology I'm not
//   // implementing it with a `graph.fold` or a `graph.map_contexts`, it would
//   // increase code reuse but would rebuild a new graph each time by adding
//   // each context one by one.
//   let Graph(graph) = graph
//   Graph({
//     use _node_id, context <- dict.map_values(graph)
//     let Context(incoming, node, outgoing) = context
//     let new_incoming = dict.map_values(incoming, fn(_id, label) { fun(label) })
//     let new_outgoing = dict.map_values(outgoing, fn(_id, label) { fun(label) })
//     Context(new_incoming, node, new_outgoing)
//   })
// }

/// Flips the direction of every edge in the graph. All incoming edges will
/// become outgoing and vice-versa.
///
pub fn reverse_edges(
  graph: Graph(Directed, value, label),
) -> Graph(Directed, value, label) {
  // Since this function doesn't change the graph's structure I'm not
  // implementing it with a `graph.fold` or a `graph.map_contexts`, it would
  // increase code reuse but would rebuild a new graph each time by adding
  // each context one by one
  let Graph(graph) = graph
  Graph({
    use _node_id, context <- dict.map_values(graph)
    let Context(incoming, node, outgoing) = context
    Context(outgoing, node, incoming)
  })
}

/// Turns an undirected graph into a directed one. Every edge connecting two
/// nodes in the original graph will be considered as a pair of edges connecting
/// the nodes going in both directions.
///
pub fn to_directed(
  graph: Graph(Undirected, value, label),
) -> Graph(Directed, value, label) {
  let Graph(graph) = graph
  Graph(graph)
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
