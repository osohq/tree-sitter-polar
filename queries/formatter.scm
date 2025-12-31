; Do not attempt to break within strings or comments
[
  (string)
  (comment)
] @leaf

(comment) @allow_blank_line_before @append_hardline

; These nodes generally only have a following space. By setting a global rule
; we can reduce the number of queries in this file. If we do need to change the
; behavior, we can write queries that supercede this.
[
  ","
  ":"
  ";"
] @prepend_antispace @append_space

; Every top-level parsed content should go to a new line. Also, allow lone empty lines if added
(source_file
  (_)+ @append_hardline @allow_blank_line_before)

(assignment_operator) @prepend_space @append_space

(dict
  "{" @append_spaced_softline
  "}" @prepend_spaced_softline)

; Resource blocks to new lines
(resource_block) @allow_blank_line_before @append_hardline

((resource_block) @append_hardline
  (resource_block) @allow_blank_line_before @prepend_hardline)

(resource_type) @append_space

; Tree-sitter (or Topiary, idk) have a nefarious limit where only the first 3 capture identifiers are read.
; Everything else is silently dropped. If you make these wider, you're hosed.
(resource_block
  scope_start: "{" @prepend_space @append_begin_scope @append_indent_start
  .
  ; If the resource block is not empty, force the first content tokens to a new line
  (_)? @prepend_hardline
  ; Suck the closing brace back in for empty resource blocks
  scope_end: "}" @prepend_antispace @prepend_end_scope @prepend_indent_end
  (#scope_id! "resource"))

(resource_block
  scope_start: "{"
  expression_end: ";" @append_hardline
  scope_end: "}")

(shorthand_rule
  (string) @append_space
  "if" @append_spaced_softline @append_indent_start
  (_)* @prepend_space
  ";" @append_indent_end @append_hardline
  (#scope_id! "shorthand_rule"))

; Rulez
(rule_block
  (rule_functor) @append_space
  "if" @append_hardline @append_indent_start
  (_)*
  ";" @append_indent_end
  (#scope_id! "rule"))

(rule_block
  [
    "or"
    "and"
  ] @prepend_space @append_hardline)

(rule_expression_functor
  name: (namespaced_identifier) @append_space
  "matches" @append_space)

; Tests
(test_header
  keyword: "test" @append_space) @append_space

(test_block
  (test_header)
  "{" @append_spaced_softline @append_begin_scope @append_indent_start
  (_)* @allow_blank_line_before
  ; Suck the closing brace back in for empty test blocks
  "}" @prepend_antispace @prepend_end_scope @prepend_indent_end
  (#scope_id! "test"))

(test_block
  (test_header)
  (test_setup) @append_hardline)

(test_setup
  "setup" @append_space
  "{" @append_spaced_softline @append_begin_scope @append_indent_start
  (_)* @allow_blank_line_before @append_hardline
  ; Suck the closing brace back in for empty test setup blocks
  "}" @prepend_antispace @prepend_end_scope @prepend_indent_end
  (#scope_id! "test_setup"))

(assertion
  keyword: _ @append_space) @append_hardline
