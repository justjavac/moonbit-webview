///|
/// Generic resource table for long-lived native handles exposed to JavaScript.
pub struct ResourceTable[T] {
  mut next_rid : Int
  values : Map[Int, T]
}

///|
pub fn[T] ResourceTable::new() -> ResourceTable[T] {
  ResourceTable::{ next_rid: 1, values: {} }
}

///|
pub fn[T] ResourceTable::add(self : ResourceTable[T], value : T) -> Int {
  let rid = self.next_rid
  self.next_rid += 1
  self.values.set(rid, value)
  rid
}

///|
pub fn[T] ResourceTable::get(self : ResourceTable[T], rid : Int) -> T? {
  self.values.get(rid)
}

///|
pub fn[T] ResourceTable::remove(self : ResourceTable[T], rid : Int) -> T? {
  let value = self.values.get(rid)
  self.values.remove(rid)
  value
}

///|
pub fn[T] ResourceTable::contains(self : ResourceTable[T], rid : Int) -> Bool {
  self.values.get(rid) is Some(_)
}

///|
pub fn[T] ResourceTable::rids(self : ResourceTable[T]) -> Array[Int] {
  let rids : Array[Int] = []
  for rid, _ in self.values {
    rids.push(rid)
  }
  rids
}
