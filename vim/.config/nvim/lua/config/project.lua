local M = {}

local map = vim.keymap.set

function M.is_triton_project()
  return vim.fn.getcwd():lower():find("triton", 1, true) ~= nil
end

function M.is_iree_project()
  return vim.fn.getcwd():find("/iree", 1, true) ~= nil
end

local function exec(command)
  vim.cmd(command)
end

function M.project_build()
  if M.is_triton_project() then
    exec("Dispatch make all")
  elseif M.is_iree_project() then
    exec("CMakeBuild")
  else
    vim.notify("Unknown project type", vim.log.levels.WARN)
  end
end

function M.project_clean()
  if M.is_triton_project() then
    exec("Dispatch ninja -C build/cmake.* clean")
  elseif M.is_iree_project() then
    exec("CMakeBuild --target clean")
  else
    vim.notify("Unknown project type", vim.log.levels.WARN)
  end
end

function M.set_pytest_compiler()
  pcall(vim.cmd, "compiler! pytest")
  if not vim.o.makeprg:match("pytest") then
    vim.opt_local.makeprg = "pytest --tb=short -q"
    vim.opt_local.errorformat = {
      "%f:%l: in %m",
      "%f:%l: %m",
      "%E%f:%l: %m",
      "%-G%.%#",
    }
  end
end

function M.test_function_at_cursor()
  local save = vim.fn.getpos(".")
  local line = vim.fn.search([[^\s*def test_\w\+(]], "bcnW")
  if line == 0 then
    line = vim.fn.search([[^\s*def test_\w\+(]], "bnW")
  end
  vim.fn.setpos(".", save)
  if line == 0 then
    return ""
  end
  return vim.fn.matchstr(vim.fn.getline(line), [[def \zstest_\w\+\ze(]])
end

function M.project_test_file()
  if M.is_triton_project() then
    M.set_pytest_compiler()
    exec("Dispatch pytest --tb=short -xvs " .. vim.fn.shellescape(vim.fn.expand("%:p")))
  elseif M.is_iree_project() then
    exec("CMakeTest -R " .. vim.fn.fnameescape(vim.fn.expand("%:t")) .. [[ --output-on-failure -E 'cuda\|metal\|vulkan\|cpu\|e2e\|cts']])
  else
    vim.notify("Unknown project type", vim.log.levels.WARN)
  end
end

function M.project_test_at_cursor()
  local test_name = M.test_function_at_cursor()
  if test_name == "" then
    vim.notify("No test function found at cursor", vim.log.levels.WARN)
    return
  end

  if M.is_triton_project() then
    M.set_pytest_compiler()
    exec("Dispatch pytest --tb=short -xvs " .. vim.fn.shellescape(vim.fn.expand("%:p") .. "::" .. test_name))
  elseif M.is_iree_project() then
    exec("CMakeTest -R " .. vim.fn.fnameescape(test_name) .. [[ --output-on-failure -E 'cuda\|metal\|vulkan\|cpu\|e2e\|cts']])
  else
    vim.notify("Unknown project type", vim.log.levels.WARN)
  end
end

function M.project_test_all()
  if M.is_triton_project() then
    exec("Dispatch make test-nogpu")
  elseif M.is_iree_project() then
    exec([[CMakeTest all -j32 --output-on-failure -E 'cuda\|metal\|vulkan\|cpu\|e2e\|cts']])
  else
    vim.notify("Unknown project type", vim.log.levels.WARN)
  end
end

function M.export_iree_tools_from_shell()
  local output = vim.fn.systemlist([[zsh -c 'export_iree_tools; echo PATH=$PATH']])
  for _, line in ipairs(output) do
    local path = line:match("^PATH=(.*)")
    if path then
      vim.env.PATH = path
    end
  end
end

function M.project_build_debug()
  if M.is_triton_project() then
    exec("Dispatch DEBUG=1 pip install -e . --no-build-isolation")
  elseif M.is_iree_project() then
    pcall(vim.cmd, "silent CMakePreset dbg -Wno-dev")
    M.export_iree_tools_from_shell()
  else
    vim.notify("Unknown project type", vim.log.levels.WARN)
  end
end

function M.project_build_release()
  if M.is_triton_project() then
    exec("Dispatch pip install -e . --no-build-isolation")
  elseif M.is_iree_project() then
    pcall(vim.cmd, "silent CMakePreset model -Wno-dev")
    M.export_iree_tools_from_shell()
  else
    vim.notify("Unknown project type", vim.log.levels.WARN)
  end
end

local function mlir_test_command()
  if vim.fn.exists("*GetMLIRTestCommand") == 1 then
    return vim.fn.GetMLIRTestCommand()
  end
  vim.notify("GetMLIRTestCommand is unavailable; is vim-mlirtools loaded?", vim.log.levels.ERROR)
  return ""
end

function M.copy_mlir_test_to_tmux()
  local command = mlir_test_command()
  if command ~= "" then
    vim.fn.setreg('"', command)
    vim.fn.system("tmux load-buffer -", command)
  end
end

function M.run_mlir_to_scratch()
  local command = mlir_test_command()
  if command ~= "" and vim.fn.exists("*RunToScratch") == 1 then
    vim.fn.RunToScratch(command)
    vim.bo.filetype = "mlir"
  end
end

function M.debug_mlir_test()
  local command = mlir_test_command()
  if command ~= "" then
    vim.cmd("Dbg " .. command)
  end
end

function M.quickfix_to_scratch()
  vim.cmd("vertical new")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.bo.filetype = "mlir"

  local lines = {}
  for _, item in ipairs(vim.fn.getqflist()) do
    local text = (item.text or ""):gsub("^%s*||%s*", "")
    table.insert(lines, text)
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

function M.generate_test_checks(scope)
  if vim.fn.exists("*GenerateTestChecks") == 1 then
    vim.fn.GenerateTestChecks(scope)
    vim.bo.filetype = "mlir"
  end
end

function M.rename_mlir_value()
  local word = vim.fn.expand("<cword>")
  local replacement = vim.fn.input("New name: ")
  if replacement == "" then
    return
  end

  local start_line = vim.fn.search([[^\s*\(func\.func\|util.func\)]], "bW")
  local end_line = vim.fn.search("^}", "W")
  if start_line == 0 or end_line == 0 then
    vim.notify("Not inside a function or function boundaries not found.", vim.log.levels.WARN)
    return
  end

  local pattern = [[\V\<]] .. vim.fn.escape(word, [[\/]]) .. [[\>]]
  local substitute = vim.fn.escape(replacement, [[\/&]])
  vim.cmd(("%d,%ds/%s/%s/gc"):format(start_line, end_line, pattern, substitute))
end

function M.setup()
  map("n", "<leader>bb", M.project_build, { silent = true })
  map("n", "<leader>bc", M.project_clean, { silent = true })
  map("n", "<leader>tt", M.project_test_file, { silent = true })
  map("n", "<leader>tu", M.project_test_at_cursor, { silent = true })
  map("n", "<leader>ta", M.project_test_all, { silent = true })
  map("n", "<leader>bt", "<cmd>CMakeBuild --target iree-test-deps<CR>", { silent = true })
  map("n", "<leader>bp", M.export_iree_tools_from_shell, { silent = true })
  map("n", "<leader>bd", M.project_build_debug, { silent = true })
  map("n", "<leader>bm", M.project_build_release, { silent = true })
  map("n", "<leader>tg", [[<cmd>CMakeTest all --output-on-failure --label-regex '^requires-gpu-cdna3$\|^driver=hip$'<CR>]], { silent = true })
  map("n", "<leader>tc", M.copy_mlir_test_to_tmux, { silent = true })
  map("n", "<leader>td", M.debug_mlir_test, { silent = true })
  map("n", "<leader>ml", "<cmd>set syntax=mlir<CR>", { silent = true })
  map("n", "<leader>tr", M.run_mlir_to_scratch, { silent = true })
  map("n", "<leader>qs", M.quickfix_to_scratch, { silent = true })
  map("n", "<leader>tf", function()
    M.generate_test_checks("file")
  end, { silent = true })
  map("n", "<leader>tb", function()
    M.generate_test_checks("buffer")
  end, { silent = true })
  map("n", "<leader>rn", M.rename_mlir_value, { silent = true })

  vim.api.nvim_create_user_command("R", function(opts)
    if vim.fn.exists("*RunToScratch") == 1 then
      vim.fn.RunToScratch(opts.args)
    end
  end, { nargs = 1 })
end

M.setup()

_G.IsTritonProject = M.is_triton_project
_G.IsIreeProject = M.is_iree_project
_G.ProjectBuild = M.project_build
_G.ProjectClean = M.project_clean
_G.SetPytestCompiler = M.set_pytest_compiler
_G.GetTestFunctionAtCursor = M.test_function_at_cursor
_G.ProjectTestFile = M.project_test_file
_G.ProjectTestAtCursor = M.project_test_at_cursor
_G.ProjectTestAll = M.project_test_all
_G.ExportIreeToolsFromShell = M.export_iree_tools_from_shell
_G.ProjectBuildDebug = M.project_build_debug
_G.ProjectBuildRelease = M.project_build_release
_G.QuickfixToScratch = M.quickfix_to_scratch
_G.Rnvar = M.rename_mlir_value

return M
