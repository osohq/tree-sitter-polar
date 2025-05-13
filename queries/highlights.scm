; highlights.scm

[
  "cut"
  "or"
  "debug"
  "print"
  "in"
  "forall"
  "if"
  "and"
  "of"
  "not"
  "matches"
  "type"
  "on"
  "global"
] @keyword

(identifier) @variable
((namespaced_identifier) @variable)
(string) @string
(boolean) @boolean
(number) @number
(resource_block name: (namespaced_identifier) @type.definition)
(resource_type) @constructor
(operator) @operator
(rule_functor name: (namespaced_identifier) @function)
(rule_functor
  parameters: (specializer
    name: (namespaced_identifier) @variable))
(rule_expression_functor name: (namespaced_identifier) @function.call)
(rule_expression_functor
  parameters: (identifier) @variable)
(comment) @comment

; test stuff
(test_header "test" @module)
(test_header name: (string) @comment)
(test_setup "setup" @module)

(test_block keyword: ["assert" "assert_not"] @keyword)
