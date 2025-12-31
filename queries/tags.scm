(resource_block
  name: (namespaced_identifier) @name) @definition.class

(rule_functor
  name: (namespaced_identifier) @name) @definition.function

(rule_expression_functor
  name: (namespaced_identifier) @name) @reference.call

(test_block
  (test_header
    name: (string) @name)) @definition.module

(test_setup
  "setup" @name) @definition.module
