import gleeunit
import graph

pub fn main() {
  gleeunit.main()
}

pub fn nodes_test() {
  assert [] == graph.new() |> graph.nodes
  assert [graph.Node(1, "a node")]
    == graph.new()
    |> graph.insert_node(graph.Node(1, "a node"))
    |> graph.nodes
}

pub fn sizes_test() {
  assert 0 == graph.new() |> graph.size
  assert 1
    == graph.new()
    |> graph.insert_node(graph.Node(1, "a node"))
    |> graph.size
}

pub fn insert_node_test() {
  let graph =
    graph.new()
    |> graph.insert_node(graph.Node(1, "a node"))

  assert graph.has_node(graph, 1)
  assert !graph.has_node(graph, 2)
}

pub fn has_edge_test() {
  let graph =
    graph.new()
    |> graph.insert_node(graph.Node(1, "a node"))
    |> graph.insert_node(graph.Node(2, "another node"))
    |> graph.insert_directed_edge("label", from: 1, to: 2)

  assert graph.has_edge(graph, from: 1, to: 2)
  assert !graph.has_edge(graph, from: 2, to: 1)
}

pub fn get_context_test() {
  assert Error(Nil) == graph.new() |> graph.get_context(1)
  let assert Ok(graph.Context(node: graph.Node(1, "a node"), ..)) =
    graph.new()
    |> graph.insert_node(graph.Node(1, "a node"))
    |> graph.get_context(of: 1)
}
