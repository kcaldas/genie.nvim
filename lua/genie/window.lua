local api = vim.api

local function open_floating_window()
    local floating_window_scaling_factor = vim.g.genie_floating_window_scaling_factor or 0.9
    
    local height = math.ceil(vim.o.lines * floating_window_scaling_factor) - 1
    local width = math.ceil(vim.o.columns * floating_window_scaling_factor)
    
    local row = math.ceil(vim.o.lines - height) / 2
    local col = math.ceil(vim.o.columns - width) / 2
    
    local opts = {
        style = 'minimal',
        relative = 'editor',
        row = row,
        col = col,
        width = width,
        height = height,
        border = 'rounded'
    }
    
    -- Create buffer if needed
    if GENIE_BUFFER == nil or vim.fn.bufwinnr(GENIE_BUFFER) == -1 then
        GENIE_BUFFER = api.nvim_create_buf(false, true)
    else
        GENIE_LOADED = true
    end
    
    -- Create floating window
    local win = api.nvim_open_win(GENIE_BUFFER, true, opts)
    
    vim.bo[GENIE_BUFFER].filetype = 'genie'
    vim.cmd('setlocal bufhidden=hide')
    vim.cmd('setlocal nocursorcolumn')
    vim.cmd('setlocal signcolumn=no')
    
    return win, GENIE_BUFFER
end

return {
    open_floating_window = open_floating_window,
}