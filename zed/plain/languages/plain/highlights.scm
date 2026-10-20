; --- ключевые слова ---
[
  "create" "based" "on" "with"
  "number" "string" "is"
  "get" "from"
  "have" "which"
  "add"
  "and"
  "store"
] @keyword

(print_statement) @keyword

; --- объявление модели ---
(create_statement name: (identifier) @type.definition)
(create_statement base: (identifier) @type)

; --- поля модели ---
(property kind: _ @keyword)                    ; number / string как тип
(property name: (identifier) @property)
(property value: (number)    @number)
(property value: (string)    @string)
(property value: (identifier) @variable)

; --- временная переменная ---
(have_statement local: (identifier) @variable.local)
(have_statement value: (number)    @number)
(have_statement value: (string)    @string)
(have_statement value: (identifier) @variable)
(have_statement model: (identifier) @type)

; --- get ---
(get_statement target: (identifier) @variable)
(get_statement target: (number)    @number)
(get_statement target: (string)    @string)
(get_statement model: (identifier) @type)

; --- add ---
(add_statement value: (number)    @number)
(add_statement value: (string)    @string)
(add_statement value: (identifier) @variable)

; --- запасной вариант ---
(identifier) @variable
