(model_decl name:   (identifier) @type)
(model_decl parent: (identifier) @type)

(field_decl name: (identifier) @property)
(field_decl value: (number)     @number)
(field_decl value: (string)     @string)
(field_decl value: (identifier) @variable)
(field_decl format: (string)    @string)
(field_decl format: (identifier) @string)

(operation model: (identifier) @type)
(operation field: (identifier) @property)
(operation value: (number)     @number)
(operation value: (string)     @string)

(query model: (identifier) @type)
(query field: (identifier) @property)

(operator) @operator
":" @punctuation.delimiter
"?" @punctuation.special
"<-" @keyword
(identifier) @variable
