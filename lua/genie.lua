local open_floating_window = require("genie.window").open_floating_window

local M = {}

GENIE_BUFFER = nil
GENIE_LOADED = false
local prev_win = -1
local win = -1

local function on_exit(job_id, code, event)
    if code ~= 0 then
        return
    end
    
    GENIE_BUFFER = nil
    GENIE_LOADED = false
    vim.cmd("silent! :checktime")
    
    if vim.api.nvim_win_is_valid(prev_win) then
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_set_current_win(prev_win)
        prev_win = -1
        win = -1
    end
end

local function exec_genie_command(cmd)
    if GENIE_LOADED == false then
        vim.fn.termopen(cmd, { on_exit = on_exit })
    end
    vim.cmd("startinsert")
end

function M.open()
    prev_win = vim.api.nvim_get_current_win()
    
    win, GENIE_BUFFER = open_floating_window()
    
    exec_genie_command('genie')
end

function M.ask(prompt)
    local cmd = {'genie', 'ask', prompt}
    vim.fn.jobstart(cmd, {
        on_stdout = function(_, data)
            if data and #data > 0 and data[1] ~= "" then
                local buf = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_buf_set_lines(buf, 0, -1, false, data)
                vim.cmd('new')
                vim.api.nvim_set_current_buf(buf)
                vim.bo[buf].buftype = 'nofile'
                vim.bo[buf].bufhidden = 'wipe'
                vim.bo[buf].modifiable = false
            end
        end,
        on_stderr = function(_, data)
            if data and #data > 0 and data[1] ~= "" then
                vim.notify("Genie error: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
            end
        end
    })
end

function M.setup(opts)
    opts = opts or {}
    
    -- Set configuration
    vim.g.genie_floating_window_scaling_factor = opts.floating_window_scaling_factor or 0.9
    
    vim.api.nvim_create_user_command('Genie', M.open, { nargs = 0 })
    vim.api.nvim_create_user_command('GenieAsk', function(args) M.ask(args.args) end, { nargs = 1 })
end

return M