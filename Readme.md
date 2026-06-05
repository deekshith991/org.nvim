
# org.nvim

My personal implementation of org-roam


## Keymaps

#### common Keymaps

| ke | command |
| -------------- | --------------- |
| s | toggle both line numbers and relative line numbers |
| q | quit the file |


#### TodoView

| Keymap | command |
| -------------- | --------------- |
| `<leader>td` | open todo_file |
| x | toggle the todo taks |
| z | add task |

#### IdeasView

| Keymap | command |
| -------------- | --------------- |
| `<leader>id` | open IdeasView |
| n | create new ideas file |
| w | save the ideas file |
| `<ctrl-s` | save the ideas file |


### Lazy.nvim 
```lua
return {
  {
    src = "deekshith991/org.nvim/",

    config = function()
      require("org").setup({
        todo_file = "~/notes/todo.md",
        ideas_directory = "~/notes/ideas/"
      })
    end,
  },
}
```
