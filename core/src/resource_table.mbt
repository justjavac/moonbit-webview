///|
/// Generic resource table for long-lived native handles exposed to JavaScript.
struct ResourceTable[T] {
  mut next_rid : Int
  values : Map[Int, T]
}

///|
/// Creates an empty resource table.
/// Resource ids start at `1` so `0` can remain available as a sentinel in
/// external protocols.
pub fn[T] ResourceTable::new() -> ResourceTable[T] {
  ResourceTable::{ next_rid: 1, values: {} }
}

///|
/// Stores one value and returns its new resource id.
/// Resource ids grow monotonically for the lifetime of the table so callers can
/// hand them to JavaScript or native code safely.
pub fn[T] ResourceTable::add(self : ResourceTable[T], value : T) -> Int {
  let rid = self.next_rid
  self.next_rid += 1
  self.values.set(rid, value)
  rid
}

///|
/// Returns one resource by id when it is still registered.
/// `None` means the id was never issued or has already been released.
pub fn[T] ResourceTable::get(self : ResourceTable[T], rid : Int) -> T? {
  self.values.get(rid)
}

///|
/// Removes one resource and returns its previous value when present.
/// This is the normal release path for long-lived native handles exposed to
/// JavaScript.
pub fn[T] ResourceTable::remove(self : ResourceTable[T], rid : Int) -> T? {
  let value = self.values.get(rid)
  self.values.remove(rid)
  value
}

///|
/// Returns whether one resource id is currently registered.
/// Use this for validation when incoming ids may have been released already.
pub fn[T] ResourceTable::contains(self : ResourceTable[T], rid : Int) -> Bool {
  self.values.get(rid) is Some(_)
}

///|
/// Returns every currently registered resource id.
/// The result is useful for bulk cleanup, diagnostics, or leak detection.
pub fn[T] ResourceTable::rids(self : ResourceTable[T]) -> Array[Int] {
  let rids : Array[Int] = []
  for rid, _ in self.values {
    rids.push(rid)
  }
  rids
}
