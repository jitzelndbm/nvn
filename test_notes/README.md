# Tests

## Link tests

test
[https://en.wikipedia.org]
[another one](https://google.com)
[Folder note that does exist](folder/)
test
[a](a.md)
[b](b.md)
[This note does not exist](gamer/)
test

## Eval blocks test

### Inline

Appends the result of the code block after the code block.

```lua, eval
return "Hello World"
```

#### Returns nothing

```lua, eval

```

### External

This replaces the content between the open and close directives

<!-- NVN_EVAL ./my_eval_script.lua -->

Hello World!

<!-- NVN_EVAL end -->
