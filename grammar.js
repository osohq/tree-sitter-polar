/**
 * @file A declarative logic programming language specialized for authorization logic.
 * @author Aru Sahni <aru@osohq.com>
 * @license Apache 2.0
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

/**
 * A mapping of keyword precedence for the parser. Mirrors the precedence rules
 * in the Polar parser.
 */
const PREC = {
  or: 1,
  and: 2,
  not: 3,
  unify: 4,
  comparison: 4,
  in: 5,
  matches: 5,
};

/**
 * Comma-separated list of `rule`, no trailing comma.
 */
function commaSep1(rule) {
  return seq(rule, repeat(seq(",", rule)));
}

/**
 * Comma-separated list of `rule` with an optional trailing comma.
 */
function commaSep1Trailing(rule) {
  return seq(rule, repeat(seq(",", rule)), optional(","));
}

module.exports = grammar({
  name: "polar",

  extras: ($) => [/\s/, $.comment],

  word: ($) => $.namespaced_identifier,

  conflicts: ($) => [],

  rules: {
    source_file: ($) =>
      repeat(
        choice(
          $.resource_block,
          $.rule_block,
          $.rule_type,
          $.declare_statement,
          $.inline_query,
          $.test_fixture,
          $.test_block,
        ),
      ),

    comment: ($) => token(seq("#", /.*/)),
    // Backslash escapes any character, including a newline; unescaped
    // newlines end the string.
    string: ($) => token(seq('"', /(?:[^"\\\n]|\\[\s\S])*/, '"')),
    // The Polar lexer accepts any character that is not ASCII punctuation or
    // whitespace in a symbol (including unicode), plus `_`, `::`-separated
    // segments, and an optional trailing `?`.
    namespaced_identifier: ($) =>
      token(
        seq(
          /[^!-\/:-@\[-\^`{-~\s0-9]/,
          /[^!-\/:-@\[-\^`{-~\s]*/,
          repeat(seq("::", /[^!-\/:-@\[-\^`{-~\s]+/)),
          optional("?"),
        ),
      ),

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

    current_unix_time: ($) => "@current_unix_time",

    // `Tag{"id"}`, `Integer{1}`, `Boolean{true}`
    object_literal: ($) =>
      seq(
        field("name", $.namespaced_identifier),
        "{",
        field("value", $.value),
        "}",
      ),

    // ConcreteValue, minus object literals
    value: ($) => choice($.string, $.number, $.boolean),

    // Any value a rule parameter or expression operand can hold
    term: ($) =>
      choice(
        $.value,
        $.object_literal,
        $.current_unix_time,
        $.namespaced_identifier,
      ),

    list: ($) => seq("[", optional(commaSep1Trailing($.term)), "]"),

    dict: ($) => seq("{", optional(commaSep1Trailing($.dict_field)), "}"),
    dict_field: ($) =>
      seq(
        field("key", $.namespaced_identifier),
        optional(seq(":", field("value", $.namespaced_identifier))),
      ),

    specializer: ($) =>
      seq(
        field("name", $.namespaced_identifier),
        ":",
        field("type", $.namespaced_identifier),
      ),

    // Rule flags are for internal use only. Accept any `@`-prefixed identifier
    // rather than enumerating them.
    rule_flags: ($) => repeat1($.rule_flag),
    rule_flag: ($) =>
      token(seq("@", /[^!-\/:-@\[-\^`{-~\s0-9][^!-\/:-@\[-\^`{-~\s]*/)),

    rule_functor: ($) =>
      seq(
        field("name", $.namespaced_identifier),
        "(",
        optional(field("parameters", commaSep1($.parameter))),
        ")",
      ),

    parameter: ($) => choice($.specializer, $.term),

    rule_block: ($) =>
      seq(
        optional($.rule_flags),
        $.rule_functor,
        optional(seq("if", field("body", $.expression))),
        ";",
      ),

    rule_type: ($) => seq("type", $.rule_functor, ";"),

    declare_statement: ($) =>
      seq(
        "declare",
        field("name", $.namespaced_identifier),
        "(",
        optional(commaSep1($.namespaced_identifier)),
        ")",
        ";",
      ),

    inline_query: ($) => seq("?=", $.expression, ";"),

    expression: ($) =>
      choice(
        $.binary_expression,
        $.not_expression,
        $.unify_expression,
        $.comparison_expression,
        $.in_expression,
        $.matches_expression,
        $.call,
        $.boolean,
        $.paren_expression,
      ),

    binary_expression: ($) =>
      choice(
        prec.left(
          PREC.or,
          seq(
            field("left", $.expression),
            field("operator", "or"),
            field("right", $.expression),
          ),
        ),
        prec.left(
          PREC.and,
          seq(
            field("left", $.expression),
            field("operator", "and"),
            field("right", $.expression),
          ),
        ),
      ),

    not_expression: ($) => prec(PREC.not, seq("not", $.expression)),

    unify_expression: ($) =>
      prec.left(
        PREC.unify,
        seq(field("left", $.term), "=", field("right", $.term)),
      ),

    comparison_operator: ($) => choice(">", ">=", "<", "<=", "!="),

    comparison_expression: ($) =>
      prec.left(
        PREC.comparison,
        seq(
          field("left", $.term),
          field("operator", $.comparison_operator),
          field("right", $.term),
        ),
      ),

    in_expression: ($) =>
      prec.left(
        PREC.in,
        seq(field("item", $.term), "in", field("iterator", $.list)),
      ),

    matches_expression: ($) =>
      prec(
        PREC.matches,
        seq(
          field("name", $.namespaced_identifier),
          field("operator", choice("matches", "matches!")),
          field("type", $.namespaced_identifier),
        ),
      ),

    call: ($) =>
      seq(
        field("name", $.namespaced_identifier),
        "(",
        optional(field("arguments", commaSep1($.term))),
        ")",
      ),

    paren_expression: ($) => seq("(", $.expression, ")"),

    resource_type: ($) => choice("actor", "resource"),

    resource_block: ($) =>
      seq(
        choice(
          seq(
            $.resource_type,
            field("name", $.namespaced_identifier),
            optional(
              seq(
                field("keyword", "extends"),
                commaSep1Trailing(
                  field("extends", $.namespaced_identifier),
                ),
              ),
            ),
          ),
          "global",
        ),
        field("scope_start", "{"),
        repeat(
          choice(
            seq($.declaration, field("expression_end", ";")),
            $.shorthand_rule,
          ),
        ),
        field("scope_end", "}"),
      ),

    // `roles = [...]`, `relations = { ... }`
    declaration: ($) =>
      seq(
        field("key", $.namespaced_identifier),
        $.assignment_operator,
        choice($.list, $.dict),
      ),

    assignment_operator: ($) => "=",

    shorthand_rule: ($) =>
      seq(
        optional($.rule_flags),
        field("head", $.term),
        "if",
        field("body", $.shorthand_expression),
        ";",
      ),

    shorthand_expression: ($) =>
      choice(
        prec.left(
          PREC.or,
          seq(
            field("left", $.shorthand_expression),
            field("operator", "or"),
            field("right", $.shorthand_expression),
          ),
        ),
        prec.left(
          PREC.and,
          seq(
            field("left", $.shorthand_expression),
            field("operator", "and"),
            field("right", $.shorthand_expression),
          ),
        ),
        $.call,
        $.global_expression,
        $.on_expression,
        $.short_term,
        seq("(", $.shorthand_expression, ")"),
      ),

    on_expression: ($) =>
      seq(field("left", $.short_term), "on", field("right", $.short_term)),

    global_expression: ($) => seq("global", $.short_term),

    short_term: ($) => choice($.namespaced_identifier, $.string),

    fact_declaration: ($) =>
      seq(
        field("name", $.namespaced_identifier),
        "(",
        optional(field("parameters", commaSep1($.fact_argument))),
        ")",
        ";",
      ),

    fact_argument: ($) => choice($.value, $.object_literal),

    test_block: ($) =>
      seq(
        field("header", $.test_header),
        "{",
        optional($.test_setup),
        repeat1($.assertion),
        "}",
      ),

    test_header: ($) => seq(field("keyword", "test"), field("name", $.string)),

    test_setup: ($) =>
      seq(
        "setup",
        "{",
        repeat(choice($.fact_declaration, $.fixture_reference)),
        "}",
      ),

    fixture_reference: ($) =>
      seq("fixture", field("name", $.namespaced_identifier), ";"),

    test_fixture: ($) =>
      seq(
        field("keyword", "test"),
        field("kind", "fixture"),
        field("name", $.namespaced_identifier),
        "{",
        repeat($.fact_declaration),
        "}",
      ),

    assertion: ($) =>
      seq(
        field("keyword", choice("assert", "assert_not")),
        field("head", $.rule_functor),
        optional(seq(field("keyword", "iff"), field("condition", $.expression))),
        ";",
      ),
  },
});
