# graph

[![Package Version](https://img.shields.io/hexpm/v/graph)](https://hex.pm/packages/graph)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/graph/)

A package for working with graphs in Gleam!

```sh
gleam add graph
```

```gleam
import graph

pub fn main() {
  let graph =
    graph.new()
    |> graph.insert_node(1, "one node")
    |> graph.insert_node(2, "anoter node")
    |> graph.insert_directed_edge("label", from: 1, to: 2)

  assert graph.has_edge(graph, from: 1, to: 2)
  assert !graph.has_edge(graph, from: 2, to: 1)
}
```
