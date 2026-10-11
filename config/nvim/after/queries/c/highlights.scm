; extends
; definitions, coloured apart from their uses (plugin/colors.lua): functions and prototypes, types, macros
(function_declarator declarator: (identifier) @definition)
(type_definition declarator: (type_identifier) @definition)
(struct_specifier name: (type_identifier) @definition body: (_))
(union_specifier name: (type_identifier) @definition body: (_))
(enum_specifier name: (type_identifier) @definition body: (_))
; a #define with a value; a bare one (include guards, feature flags) is no definition
(preproc_def name: (identifier) @definition value: (_))
(preproc_function_def name: (identifier) @definition)

; goto jumps like return: control flow
"goto" @keyword.return

; #pragma, #error and the like are not branches, unlike the #if family
(preproc_directive) @keyword.directive.other
