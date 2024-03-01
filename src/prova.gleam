import graph
import gleam/io

pub fn main() {
  let graph =
    graph.new()
    |> graph.insert_node(0, Nil)
    |> graph.insert_node(1, Nil)
    |> graph.insert_node(2, Nil)
    |> graph.insert_node(3, Nil)
    |> graph.insert_node(4, Nil)
    |> graph.insert_edge(0, 1, Nil)
    |> graph.insert_edge(1, 0, Nil)
    |> graph.insert_edge(0, 2, Nil)
    |> graph.insert_edge(2, 0, Nil)
    |> graph.insert_edge(1, 2, Nil)
    |> graph.insert_edge(2, 1, Nil)
    |> graph.insert_edge(1, 3, Nil)
    |> graph.insert_edge(3, 1, Nil)
    |> graph.insert_edge(2, 4, Nil)
    |> graph.insert_edge(4, 2, Nil)
    |> graph.insert_edge(4, 3, Nil)
    |> graph.insert_edge(3, 4, Nil)

  io.debug(graph.bfs(graph, 0))
}
