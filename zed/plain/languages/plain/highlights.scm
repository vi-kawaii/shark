; --- пунктуация и операторы ---
[":" "?"] @punctuation.delimiter
"<-" @operator
(operator) @operator

; --- объявление модели ---
(model_decl name: (identifier) @type.definition)
(model_decl parent: (identifier) @type)

; --- поля ---
(field_decl name: (identifier) @property)
(field_decl value: (number)     @number)
(field_decl value: (string)     @string)
(field_decl value: (identifier) @variable)

(field_decl format: (identifier) @string.special)
(field_decl format: (string)     @string.special)
(field_decl format: (number)     @number.special)

; --- операция над полем ---
(operation model: (identifier) @type)
(operation field: (identifier) @property)
(operation value: (number)     @number)
(operation value: (string)     @string)
(operation value: (identifier) @variable)

; --- запрос ---
(query model: (identifier) @type)
(query field: (identifier) @property)

; --- запасной вариант ---
(identifier) @variable
