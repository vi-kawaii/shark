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
(property name: (identifier) @property)
(property value: (value (number)     @number))
(property value: (value (string)     @string))
(property value: (value (identifier) @variable))

; --- временная переменная ---
(have_statement local: (identifier) @variable.local)
(have_statement value: (value (number)     @number))
(have_statement value: (value (string)     @string))
(have_statement value: (value (identifier) @variable))
(have_statement model: (identifier) @type)

; --- get ---
(get_statement target: (value (identifier) @variable))
(get_statement target: (value (number)     @number))
(get_statement target: (value (string)     @string))
(get_statement model: (identifier) @type)

; --- add ---
(add_statement value: (value (number)     @number))
(add_statement value: (value (string)     @string))
(add_statement value: (value (identifier) @variable))

; --- запасной вариант ---
(identifier) @variable
