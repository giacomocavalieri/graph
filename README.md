# graph

[![Package Version](https://img.shields.io/hexpm/v/graph)](https://hex.pm/packages/graph)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/graph/)
![Supports all targets](https://img.shields.io/badge/supports-all_targets-ffaff3)

A package for working with graphs in Gleam!

> While the package already exposes all functions you might need to implement
> complex graphs algorithms, it might still be missing some crucial functions
> to provide a pleasant developer experience working with graphs.
>
> This is still a work in progress and I'm trying to figure out the best API to
> expose, so if you think something is missing, _please open an issue!_

```sh
gleam add graph
```

```gleam
import graph

pub fn main() {
  let my_graph =
    graph.new()
    |> graph.insert_node(1, "one node")
    |> graph.insert_node(2, "other node")
    |> graph.insert_directed_edge("edge label", from: 1, to: 2)

  my_graph |> graph.has_edge(from: 1, to: 2)
  // -> True

  my_graph |> graph.has_edge(from: 2, to: 1)
  // -> False
}
```
