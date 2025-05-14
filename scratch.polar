actor User {



}
resource Organization { roles = ["viewer", "owner"];
  permissions = ["view", "edit"]; "view" if "viewer";
  "edit" if "owner";
  "viewer" if "owner";
}

has_permission(u: User, r: Repository) if o matches Organization and parent(r, o) and has_permission(u, o);



