resource Organization{   }

actor User { #uses?
  roles=["reader", "writer"]; relations = { parent: Organization };
}

negation_hack(_, _, );

negated_rule(user: User) if
  not has_permission(user, "edit");
