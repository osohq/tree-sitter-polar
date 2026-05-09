resource Organization{   }

actor User { #uses?
  roles=["reader", "writer"]; relations = { parent: Organization };
}

negation_hack(_, _, );

negated_rule(user: User) if
  not has_permission(user, "edit");

has_permission(user:User, "edit", organization: Organization) if has_role(user,"admin",organization) or has_role(user,"superadmin", organization);

# This is a top-level comment
has_permission(bot:Bot, "view", organization:Organization) if has_role(bot, "unprivileged", organization);

test "Organization" {
  # in-scope comment
  setup {
    has_role(User{"alice"}, "viewer", Organization{"example"});
    has_role(User{"bob"}, "owner", Organization{"example"});
  }
}
