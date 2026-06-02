
# org.nvim

My personel implementation of org-roam


## Keymaps
#### TodoView

| Keymap | command |
| -------------- | --------------- |
| `<leader>td` | open todo_file |
| x | toggle the todo taks |
| z | add task |

### Lazy.nvim 
```lua
return {
  {
    src = "deekshith991/org.nvim/",

    config = function()
      require("org").setup({ todo_file = "~/notes/todo.md" })
    end,
  },
}
```
