test "Organization roles and permissions" {
  setup {
    has_role(User{"alice"}, "viewer", Organization{"example"});
  }
  assert     allow(User{"bob"}, "edit", Organization{"example"});
}
