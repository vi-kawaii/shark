;; ---------- декларации моделей ----------
(model_decl   name: (identifier) @type)
(reopen_decl  name: (identifier) @type)
(view_decl    name: (identifier) @type)
(view_decl  parent: (identifier) @type)

;; ---------- поля в model_decl ----------
(field_decl name:  (identifier) @property)
(field_decl value: (number)     @number)
(field_decl value: (string)     @string)

;; голые имена в -> X:
(name_decl name: (identifier) @type)

;; ---------- строки view_decl ----------
;; path здесь — «что показываем» → property
(view_row path: (path (identifier) @property))
(view_row spec: (identifier) @string)
(view_row spec: (number)     @number)
(view_row spec: (string)     @string)

;; ---------- операции / запросы ----------
;; path здесь — «с какой моделью работаем» → type
(operation path:  (path (identifier) @type))
(operation op:    (operator) @operator)
(operation value: (number)   @number)
(operation value: (string)   @string)

(query path: (path (identifier) @type))

;; ---------- пунктуация / ключевые токены ----------
"->" @keyword
"<-" @keyword
":"  @punctuation.delimiter
"?"  @punctuation.special
