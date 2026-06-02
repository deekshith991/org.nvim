
# org.nvim

My personel implementation of org-roam

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

