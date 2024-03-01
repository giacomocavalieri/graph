import gleam/order.{type Order, Eq, Gt, Lt}

pub opaque type Heap(a) {
  Heap(root: HeapRepr(a), compare: fn(a, a) -> Order)
}

type HeapRepr(a) {
  Empty
  Cons(a, List(HeapRepr(a)))
}

pub fn new(compare: fn(a, a) -> Order) -> Heap(a) {
  Heap(Empty, compare)
}

pub fn add(to heap: Heap(a), this item: a) -> Heap(a) {
  let Heap(heap, compare) = heap
  let heap = merge(heap, Cons(item, []), compare)
  Heap(heap, compare)
}

pub fn pop_min(from heap: Heap(a)) -> Result(#(a, Heap(a)), Nil) {
  case heap {
    Heap(Empty, _) -> Error(Nil)
    Heap(Cons(min, rest), compare) -> {
      let remaining = merge_all(rest, compare)
      Ok(#(min, Heap(remaining, compare)))
    }
  }
}

pub fn min(in heap: Heap(a)) -> Result(a, Nil) {
  case heap {
    Heap(Empty, _) -> Error(Nil)
    Heap(Cons(min, _), _) -> Ok(min)
  }
}

fn merge(
  one: HeapRepr(a),
  other: HeapRepr(a),
  compare: fn(a, a) -> Order,
) -> HeapRepr(a) {
  case one, other {
    Empty, res | res, Empty -> res
    Cons(min_one, rest_one), Cons(min_other, rest_other) ->
      case compare(min_one, min_other) {
        Lt | Eq -> Cons(min_one, [other, ..rest_one])
        Gt -> Cons(min_other, [one, ..rest_other])
      }
  }
}

fn merge_all(
  heaps: List(HeapRepr(a)),
  compare: fn(a, a) -> Order,
) -> HeapRepr(a) {
  case heaps {
    [] -> Empty
    [heap] -> heap
    [one_heap, other_heap, ..heaps] ->
      merge(one_heap, other_heap, compare)
      |> merge(merge_all(heaps, compare), compare)
  }
}
