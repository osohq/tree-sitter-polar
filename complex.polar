# Actors are the who. Most of the time, this is a User
# https://www.osohq.com/docs/guides/model-your-apps-authz#actors-and-resources
actor User {}

# This is a resource block that is used for grouping authorization 
# logic pertaining to a particular type of resource.
# A resource represents an application component that we wish to protect.
# https://www.osohq.com/docs/reference/glossary#resource-blocks
resource Organization {
  roles = ["viewer", "owner"];
  permissions = ["view", "edit"];

  # These are permissions for the Organization resource
  "view" if "viewer";
  "edit" if "owner";

  # Organization owners inherit all permissions that Organization viewers have
  "viewer" if "owner";
}

# This is an example of a different resource block 
resource Repository {
  roles = ["viewer", "owner", "contributor"];
  permissions = ["view", "edit", "create"];

  # This is an example of how we can define the relationship
  # between resources. Relations are set within the resource block.
  # This relation is named parent and it says that Repository resource
  # is related to Organization.
  # https://www.osohq.com/docs/reference/more/resource-blocks#relation-declarations
  relations = { parent: Organization };

  "view" if "viewer";
  "edit" if "contributor";
  "create" if "owner";

  # contributors are also viewers
  # owners are also contributors
  "viewer" if "contributor"; "contributor" if "owner";
  # roles are inherited from the parent organization
  "viewer" if "viewer" on "parent";
  "owner" if "owner" on "parent";
}

has_permission(u: User, r: Repository) if o matches Organization and parent(r, o) and has_permission(u, o);

# These are examples of how to test the Policy logic.
# https://www.osohq.com/docs/guides/policy-tests
test "Organization roles and permissions" {
  # Authorization decisions require data. This is where you can
  # define the test data. The test data is defined in a format
  # that Oso Cloud refers to as Facts.
  # https://www.osohq.com/docs/concepts/oso-cloud-data-model#facts
  setup {
    has_role(User{"alice"}, "viewer", Organization{"example"});
    has_role(User{"bob"}, "owner", Organization{"example"});
  }

  # This is how we assert that a user is authorized 
  # to perform a particular action or not
  assert     allow(User{"alice"}, "view", Organization{"example"}); assert     allow(User{"bob"}, "view", Organization{"example"}); assert_not allow(User{"alice"}, "edit", Organization{"example"}); assert     allow(User{"bob"}, "edit", Organization{"example"}); }

test "Repository roles and permissions" {
  setup {
    has_role(User{"alice"}, "viewer", Repository{"example"});
    has_role(User{"bob"}, "owner", Repository{"example"});
    has_role(User{"charlie"}, "contributor", Repository{"example"});
  }
  assert     allow(User{"alice"}, "view", Repository{"example"});
  assert     allow(User{"bob"}, "view", Repository{"example"});
  assert     allow(User{"charlie"}, "view", Repository{"example"});
  assert_not allow(User{"alice"}, "edit", Repository{"example"});
  assert     allow(User{"bob"}, "edit", Repository{"example"});
  assert     allow(User{"charlie"}, "edit", Repository{"example"});
  assert_not allow(User{"alice"}, "create", Repository{"example"});
  assert     allow(User{"bob"}, "create", Repository{"example"});
  assert_not allow(User{"charlie"}, "create", Repository{"example"});
}

test "Repository parent relation" {
  setup {
    has_relation(Repository{"example"}, "parent", Organization{"parentOrganization"});
    has_role(User{"alice"}, "viewer", Organization{"parentOrganization"});
    has_role(User{"bob"}, "owner", Organization{"parentOrganization"});
  }
  assert     allow(User{"alice"}, "view", Repository{"example"});
  assert     allow(User{"bob"}, "view", Repository{"example"});
  assert_not allow(User{"charlie"}, "view", Repository{"example"});
  assert_not allow(User{"dave"}, "view", Repository{"example"});
  assert_not allow(User{"alice"}, "edit", Repository{"example"});
  assert     allow(User{"bob"}, "edit", Repository{"example"});
  assert_not allow(User{"charlie"}, "edit", Repository{"example"});
  assert_not allow(User{"dave"}, "edit", Repository{"example"});
  assert_not allow(User{"alice"}, "create", Repository{"example"});
  assert     allow(User{"bob"}, "create", Repository{"example"});
}

