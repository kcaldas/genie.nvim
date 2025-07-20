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

local function get_context()
    local context = ""
    local file_path = vim.fn.expand("%:p")
    
    -- Add file reference if we have one
    if file_path ~= "" then
        local relative_path = vim.fn.fnamemodify(file_path, ":~:.")
        context = context .. "@" .. relative_path .. "\n\n"
    end
    
    -- Check for visual selection
    local mode = vim.fn.mode()
    if mode:match("[vV]") then
        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")
        local start_line = start_pos[2] - 1
        local end_line = end_pos[2]
        
        local selected_lines = vim.api.nvim_buf_get_lines(0, start_line, end_line, false)
        
        if mode == 'v' then -- Visual character mode
            selected_lines[1] = string.sub(selected_lines[1], start_pos[3])
            selected_lines[#selected_lines] = string.sub(selected_lines[#selected_lines], 1, end_pos[3])
        end
        
        if #selected_lines > 0 then
            context = context .. "Selected code:\n```" .. vim.bo.filetype .. "\n"
            context = context .. table.concat(selected_lines, "\n") .. "\n"
            context = context .. "```\n\n"
        end
    end
    
    return context
end

function M.edit()
    local context = get_context()
    
    -- Create a new buffer for editing the prompt
    local buf = vim.api.nvim_create_buf(false, true)
    
    -- Prepare the content for the buffer
    local lines = {}
    
    -- Add context if we have any
    if context ~= "" then
        local context_lines = vim.split(context, "\n")
        vim.list_extend(lines, context_lines)
        table.insert(lines, "")
    end
    
    -- Add a simple prompt area
    table.insert(lines, "Question: ")
    
    -- Set the content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Open in a new window
    vim.cmd('new')
    vim.api.nvim_set_current_buf(buf)
    
    -- Set buffer options
    vim.bo[buf].buftype = 'acwrite'
    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].filetype = 'markdown'
    
    -- Position cursor at end of "Question: " line
    local question_line = #lines
    vim.api.nvim_win_set_cursor(0, {question_line, string.len("Question: ")})
    
    -- Set up keymaps for this buffer
    local function send_to_genie()
        local all_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local full_content = table.concat(all_lines, "\n")
        
        if full_content:gsub("%s", "") ~= "" then
            vim.cmd('bdelete!')
            
            -- Send the full buffer content directly to genie
            vim.notify("Genie: Thinking...", vim.log.levels.INFO)
            
            vim.system({'genie', 'ask', full_content}, {
                text = true,
            }, function(result)
                if result.code == 0 and result.stdout then
                    vim.schedule(function()
                        local lines = vim.split(result.stdout, "\n")
                        local response_buf = vim.api.nvim_create_buf(false, true)
                        vim.api.nvim_buf_set_lines(response_buf, 0, -1, false, lines)
                        vim.cmd('new')
                        vim.api.nvim_set_current_buf(response_buf)
                        vim.bo[response_buf].buftype = 'nofile'
                        vim.bo[response_buf].bufhidden = 'wipe'
                        vim.bo[response_buf].modifiable = false
                        vim.bo[response_buf].filetype = 'markdown'
                    end)
                else
                    vim.schedule(function()
                        if result.code ~= 0 then
                            vim.notify("Genie failed with exit code: " .. result.code, vim.log.levels.ERROR)
                            if result.stderr then
                                vim.notify("Error: " .. result.stderr, vim.log.levels.ERROR)
                            end
                        else
                            vim.notify("Genie: No output received", vim.log.levels.WARN)
                        end
                    end)
                end
            end)
        else
            vim.notify("Buffer is empty", vim.log.levels.WARN)
        end
    end
    
    local function cancel_edit()
        vim.cmd('bdelete!')
    end
    
    -- Set up buffer-local keymaps
    vim.keymap.set('n', '<CR>', send_to_genie, { buffer = buf, desc = "Send to Genie" })
    vim.keymap.set('n', '<Esc>', cancel_edit, { buffer = buf, desc = "Cancel" })
    vim.keymap.set('n', 'q', cancel_edit, { buffer = buf, desc = "Cancel" })
    
    -- Add instructions at the top as comments
    vim.api.nvim_buf_set_lines(buf, 0, 0, false, {
        "<!-- Press <CR> to send, <Esc> or 'q' to cancel -->",
        "",
    })
    
    -- Enter insert mode at the question area
    vim.cmd('startinsert')
end

function M.ask(prompt)
    local context = get_context()
    local full_prompt = context .. "Question: " .. prompt
    
    -- If no context, just use the prompt directly
    if context == "" then
        full_prompt = prompt
    end
    
    -- Show progress notification
    vim.notify("Genie: Thinking...", vim.log.levels.INFO)
    
    vim.system({'genie', 'ask', full_prompt}, {
        text = true,
    }, function(result)
        if result.code == 0 and result.stdout then
            vim.schedule(function()
                local lines = vim.split(result.stdout, "\n")
                local buf = vim.api.nvim_create_buf(false, true)
                vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
                vim.cmd('new')
                vim.api.nvim_set_current_buf(buf)
                vim.bo[buf].buftype = 'nofile'
                vim.bo[buf].bufhidden = 'wipe'
                vim.bo[buf].modifiable = false
                vim.bo[buf].filetype = 'markdown'
            end)
        else
            vim.schedule(function()
                if result.code ~= 0 then
                    vim.notify("Genie failed with exit code: " .. result.code, vim.log.levels.ERROR)
                    if result.stderr then
                        vim.notify("Error: " .. result.stderr, vim.log.levels.ERROR)
                    end
                else
                    vim.notify("Genie: No output received", vim.log.levels.WARN)
                end
            end)
        end
    end)
end

function M.setup(opts)
    opts = opts or {}
    
    -- Set configuration
    vim.g.genie_floating_window_scaling_factor = opts.floating_window_scaling_factor or 0.9
    
    vim.api.nvim_create_user_command('Genie', M.open, { nargs = 0 })
    vim.api.nvim_create_user_command('GenieAsk', function(args) M.ask(args.args) end, { nargs = 1 })
    vim.api.nvim_create_user_command('GenieEdit', M.edit, { nargs = 0 })
end

return M