/**
 * @file A declarative logic programming language specialized for authorization logic.
 * @author Aru Sahni <aru@osohq.com>
 * @license Apache 2.0
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

module.exports = grammar({
  name: "polar",

  conflicts: ($) => [
    [$.rule_functor, $.fact_declaration],
    [$.keyword, $.rule_expression_functor],
    [$.rule_expression_functor, $.term],
  ],
  precedences: ($) => [[$.number, $.operator]],

  rules: {
    source_file: ($) =>
      repeat(
        choice(
          $.resource_block,
          $.comment,
          $.rule_block,
          $.rule_type,
          $.fact_declaration,
          $.inline_query,
          $.test_block,
        ),
      ),
    comment: ($) => token(seq("#", /.*/)),
    string: ($) => seq('"', /[^"]*/, '"'),
    identifier: ($) => /[a-zA-Z_][a-zA-Z0-9_]*/,
    namespaced_identifier: ($) => /[a-zA-Z_][a-zA-Z0-9_]*(?:::[a-zA-Z0-9_]+)*/,

    number: ($) =>
      seq(
        optional(choice("+", "-")),
        /\d+/,
        optional(
          choice(
            seq(
              ".",
              /\d+/,
              optional(seq("e", optional(choice("+", "-")), /\d+/)),
            ),
            seq("e", optional(choice("+", "-")), /\d+/),
          ),
        ),
      ),

    boolean: ($) => choice("true", "false"),

    keyword: ($) =>
      choice(
        "cut",
        "or",
        "debug",
        "print",
        "in",
        "forall",
        "if",
        "iff",
        "and",
        "of",
        "not",
        "matches",
        "type",
        "on",
        "global",
      ),

    operator: ($) => choice("+", "-", "*", "/", "<", ">", "=", "!"),
    assignment_operator: ($) => "=",

    rule_type: ($) => seq("type", $.rule_functor, ";"),
    resource_type: ($) => choice("actor", "resource"),

    rule_block: ($) =>
      seq(
        $.rule_functor,
        optional(
          seq(
            "if",
            repeat($.comment),
            $.rule_expression_functor,
            repeat($.comment),
            repeat(
              seq(
                choice("and", "or"),
                repeat($.comment),
                $.rule_expression_functor,
              ),
            ),
          ),
        ),
        ";",
      ),

    rule: ($) =>
      seq(
        choice(
          $.rule_functor,
          seq("if", choice($.term, $.rule_expression_functor), ";"),
          ";",
        ),
      ),

    rule_functor: ($) =>
      seq(
        field("name", $.namespaced_identifier),
        "(",
        field(
          "parameters",
          seq(
            choice($.specializer, $.value),
            optional(repeat(seq(",", choice($.specializer, $.value)))),
          ),
        ),
        ")",
      ),

    rule_expression_functor: ($) =>
      choice(
        seq(
          field("name", $.namespaced_identifier),
          "matches",
          field("type", $.namespaced_identifier),
        ),
        seq(
          optional(field("keyword", "not")),
          field("name", $.namespaced_identifier),
          "(",
          field(
            "parameters",
            seq(
              choice($.value, $.identifier),
              optional(repeat(seq(",", choice($.value, $.identifier)))),
            ),
          ),
          ")",
        ),
        seq(
          optional(field("keyword", "not")),
          "(",
          repeat($.comment),
          $.rule_expression_functor,
          repeat($.comment),
          repeat(
            seq(
              choice("and", "or"),
              repeat($.comment),
              $.rule_expression_functor,
            ),
          ),
          ")",
        ),
      ),

    object_literal: ($) =>
      seq(
        field("name", $.namespaced_identifier),
        "{",
        field("value", $.value),
        "}",
      ),

    value: ($) => choice($.string, $.number, $.boolean, "_"),

    list: ($) => seq("[", repeat(choice($.term, ",")), "]"),

    dict: ($) =>
      seq(
        "{",
        repeat(choice($.comment, seq($.dict_field, optional(",")))),
        "}",
      ),
    dict_field: ($) =>
      seq(
        field("key", $.identifier),
        ":",
        field("value", $.namespaced_identifier),
      ),
    parens: ($) => seq("(", repeat($.term), ")"),

    specializer: ($) =>
      seq(
        field("name", $.namespaced_identifier),
        ":",
        field("type", $.namespaced_identifier),
      ),

    inline_query: ($) => seq("?=", $.term, ";"),

    shorthand_rule: ($) =>
      seq(
        $.string,
        "if",
        choice(repeat($.term), $.rule_expression_functor),
        ";",
      ),

    resource_block: ($) =>
      seq(
        optional(field("identifier", $.namespaced_identifier)),
        choice(
          seq(
            $.resource_type,
            field("name", $.namespaced_identifier),
            optional(
              seq(
                field("keyword", "extends"),
                field("identifier", $.namespaced_identifier),
              ),
            ),
          ),
          "global",
        ),
        field("scope_start", "{"),
        repeat(
          seq(
            choice(
              seq($.relation_declaration, field("expression_end", ";")),
              seq($.declaration, field("expression_end", ";")),
              $.shorthand_rule,
              $.comment,
            ),
          ),
        ),
        field("scope_end", "}"),
      ),

    relation_declaration: ($) =>
      seq("{", repeat(choice($.specializer, $.comment, ",")), "}"),

    test_block: ($) =>
      seq(
        field("header", $.test_header),
        "{",
        repeat($.comment),
        optional(seq($.test_setup, repeat(choice($.assertion, $.comment)))),
        "}",
      ),

    test_header: ($) => seq(field("keyword", "test"), field("name", $.string)),

    test_setup: ($) =>
      seq(
        "setup",
        "{",
        repeat(choice($.fact_declaration, $.comment, $.fixture)),
        "}",
      ),

    fact_declaration: ($) =>
      seq(
        field("name", $.namespaced_identifier),
        "(",
        field(
          "parameters",
          seq(
            choice($.object_literal, $.value),
            repeat(seq(",", choice($.object_literal, $.value))),
          ),
        ),
        ")",
        ";",
      ),

    assertion: ($) =>
      seq(
        field("keyword", choice("assert", "assert_not")),
        field("predicate", $.identifier),
        "(",
        field(
          "parameters",
          seq(
            choice($.object_literal, $.specializer, $.value),
            repeat(seq(",", choice($.object_literal, $.specializer, $.value))),
          ),
        ),
        ")",
        optional(
          seq(
            field("keyword", "iff"),
            field("name", $.namespaced_identifier),
            field("keyword", choice("in", "not in")),
            $.list,
          ),
        ),
        ";",
      ),

    fixture: ($) => seq("test", repeat(choice($.comment, $.rule)), "fixture"),

    declaration: ($) =>
      seq(
        choice("relations", "permissions", field("keyword", "roles")),
        $.assignment_operator,
        choice($.list, $.dict),
      ),

    term: ($) =>
      choice(
        $.comment,
        $.string,
        $.number,
        $.keyword,
        $.declaration,
        $.operator,
        $.boolean,
        $.object_literal,
        $.list,
        $.dict,
        $.parens,
      ),
  },
});
