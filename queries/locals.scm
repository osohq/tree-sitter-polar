(source_file) @local.scope
(resource_block
  name: (namespaced_identifier) @local.definition)
(namespaced_identifier) @local.reference
(rule_functor) @local.scope
(rule_functor
  parameters: (specializer
       name: (namespaced_identifier) @local.definition))
(rule_functor
  parameters: (specializer
       type: (namespaced_identifier) @local.reference))

(test_block) @local.scope
