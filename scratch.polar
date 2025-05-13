grandfather(grandchild: String, grandparent: String) if
  parent matches String and
  father(grandchild, parent) and
  father(parent, grandparent);
